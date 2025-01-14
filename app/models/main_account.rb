class MainAccount < ApplicationRecord
  # Callbacks
  after_save :adjust_sub_account_balances, if: :saved_change_to_balance?

  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :sub_accounts, dependent: :destroy
  has_many :main_transactions, dependent: :destroy
  has_many :shared_main_account_users, dependent: :destroy
  has_many :partners, through: :shared_main_account_users, source: :user

  # Validations
  validates :title, presence: true
  validates :available_percentage, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  private

  ### CALLBACKS ###

  def adjust_sub_account_balances
    return if sub_accounts.empty?

    # Calculate the delta from the most recent transaction affecting the balance
    delta = saved_change_to_balance[1] - saved_change_to_balance[0]

    sub_accounts.each do |sub_account|
      # Adjust each sub-account balance proportionally based on its percentage
      sub_delta = (sub_account.percentage / 100.0) * delta
      sub_account.update_column(:balance, sub_account.balance + sub_delta)
    end
  end
end
