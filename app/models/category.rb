class Category < ApplicationRecord
  # Associations
  belongs_to :sub_account
  has_many :sub_account_transactions

  # Validations
  validates :title, presence: true, uniqueness: { scope: :sub_account_id, message: "You already have a category with the same title" }

end
