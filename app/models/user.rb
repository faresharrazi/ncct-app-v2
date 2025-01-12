class User < ApplicationRecord
  after_create :create_main_account

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Associations
  has_many :main_accounts, foreign_key: :owner_id, dependent: :destroy
  has_many :transactions, foreign_key: :creator_id, class_name: 'Transaction'
  has_many :shared_main_account_users, dependent: :destroy
  has_many :shared_main_accounts, through: :shared_main_account_users, source: :main_account

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Instance Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  private

  # Automatically create a main account after user creation
  def create_main_account
    main_accounts.create!(
      title: "Main Account",
      available_percentage: 100.0,
      currency: "€"
    )
  end
end
