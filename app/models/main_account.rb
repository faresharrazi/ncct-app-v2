class MainAccount < ApplicationRecord
  # Callbacks
  after_commit :recalculate_sub_account_balances
  after_create :ensure_default_categories

  # Associations
  belongs_to :owner, class_name: 'User'

  has_many :sub_accounts, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :shared_main_account_users, dependent: :destroy
  has_many :partners, through: :shared_main_account_users, source: :user

  # Validations
  validates :title, presence: true
  validates :available_percentage, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  private
  
  def ensure_default_categories
    categories.find_or_create_by!(title: "Income")
    categories.find_or_create_by!(title: "Expense")
  end

  # Recalculate balances for all sub-accounts based on their percentage
  def recalculate_sub_account_balances
    sub_accounts.each do |sub_account|
      sub_account_balance = (sub_account.percentage / 100.0) * balance
      sub_account.update_column(:balance, sub_account_balance)
    end
  end
end
