class User < ApplicationRecord
  
  after_create :create_main_account

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  
  has_many :main_accounts, foreign_key: :owner_id, dependent: :destroy
  has_many :transactions, foreign_key: :creator_id, class_name: 'Transaction'

  # If you want to keep track of MainAccounts shared with the user,
  # you can do something like this:
  has_many :shared_main_account_users
  has_many :shared_main_accounts, through: :shared_main_account_users, source: :main_account
  
  validates :first_name, presence: true
  validates :last_name, presence: true

    

  private

  def create_main_account
    main_accounts.create!(
      title: "Main Account",
      available_percentage: 100.0,
      currency: "EUR"
    )
  end
end
