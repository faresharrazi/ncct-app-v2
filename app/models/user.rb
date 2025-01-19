class User < ApplicationRecord
  # Callbacks
  after_create :create_main_account
  before_destroy :handle_main_accounts

  # Devise Modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Associations
  has_and_belongs_to_many :main_accounts, join_table: 'main_accounts_users'
  has_many :main_transactions, through: :main_accounts
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
    default_main_account = MainAccount.create!(
      title: "Main Account",
      available_percentage: 100.0,
      currency: "€",
      balance: 0.0, # Initialize with a default balance
      shareable_balance: 0.0 # Initialize with a default shareable balance
    )
    default_main_account.owners << self
  end

  def handle_main_accounts
    main_accounts.each do |main_account|
      Rails.logger.debug "Processing main account: #{main_account.id}"
      if main_account.owners.count == 1
        Rails.logger.debug "Destroying main account: #{main_account.id}"
        main_account.destroy
      else
        Rails.logger.debug "Removing user from main account: #{main_account.id}"
        main_account.owners.delete(self)
      end
    end
  end

end