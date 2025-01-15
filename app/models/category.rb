class Category < ApplicationRecord
  # Associations
  belongs_to :sub_account

  # Validations
  validates :title, presence: true

end
