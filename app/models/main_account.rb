class MainAccount < ApplicationRecord

  after_commit :recalculate_balance

  belongs_to :owner, class_name: 'User'
  
  has_many :sub_accounts, dependent: :destroy
  has_many :shared_main_account_users, dependent: :destroy
  has_many :partners, through: :shared_main_account_users, source: :user

  validates :title, presence: true
  validates :available_percentage, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  
  private
  
  def recalculate_balance
    new_balance = sub_accounts.sum(:balance)
    update_column(:balance, new_balance)
  end
  
end
