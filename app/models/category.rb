class Category < ApplicationRecord
  # Associations
  belongs_to :sub_account
  has_many :sub_account_transactions

  # Validations
  validates :title, presence: true

end
