class User < ApplicationRecord
  # Callbacks
  after_create :create_main_account

  # Devise Modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Associations
  has_many :main_accounts, foreign_key: :owner_id, dependent: :destroy
  has_many :main_transactions, through: :main_accounts, source: :main_transactions
  has_many :shared_main_account_users, dependent: :destroy
  has_many :shared_main_accounts, through: :shared_main_account_users, source: :main_account

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Instance Methods

  # Returns the user's full name
  def full_name
    "#{first_name} #{last_name}"
  end

  private

  # Automatically create a default main account for the user after they are created
  def create_main_account
    main_accounts.create!(
      title: "Main Account",
      available_percentage: 100.0,
      currency: "€",
      balance: 0.0, # Initialize with a default balance
      shareable_balance: 0.0 # Initialize with a default shareable balance
    )
  end
end
