class User < ApplicationRecord
  # Callbacks
  after_create :create_main_account

  # Devise Modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :main_account, optional: true
  has_many :main_transactions, through: :main_account, source: :main_transactions
  has_many :main_accounts_users, dependent: :destroy, class_name: 'MainAccountsUser'
  has_many :shared_main_account_users, dependent: :destroy
  has_many :sub_accounts, through: :main_account



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
    main_account = MainAccount.create!(
      title: "Main Account",
      available_percentage: 100.0,
      currency: "€",
      balance: 0.0, # Initialize with a default balance
      shareable_balance: 0.0 # Initialize with a default shareable balance
    )
    main_account.owners << self
    self.main_account = main_account
    save!
  end
end