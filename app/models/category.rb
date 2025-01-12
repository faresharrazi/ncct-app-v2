class Category < ApplicationRecord
  # Callbacks
  before_destroy :check_if_default
  before_destroy :reassign_transactions_to_default

  # Associations
  belongs_to :sub_account, optional: true
  has_many :transactions, dependent: :nullify

  # Validations
  validates :title, presence: true

  private

  # Prevent deletion of the default category
  def check_if_default
    if sub_account.default_category_id == id
      errors.add(:base, "Cannot delete the default category. Assign a new default category first.")
      throw :abort
    end
  end

  # Reassign transactions to the default category before deletion
  def reassign_transactions_to_default
    default_category = sub_account.default_category
    return unless default_category.present? && default_category != self

    transactions.update_all(category_id: default_category.id)
  end
end
