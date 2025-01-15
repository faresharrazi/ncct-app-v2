class Category < ApplicationRecord
  # Associations
  belongs_to :sub_account, optional: true
  has_many :transactions, class_name: 'SubAccountTransaction', dependent: :nullify

  # Validations
  validates :title, presence: true

  # No callbacks for deletion to keep it straightforward
end
