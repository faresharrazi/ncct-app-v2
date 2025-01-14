class Category < ApplicationRecord
  # Associations
  belongs_to :sub_account, optional: true
  has_many :transactions, dependent: :nullify

  # Validations
  validates :title, presence: true

  # Callbacks
  before_destroy :prevent_default_category_deletion, if: :default_category?
  before_destroy :reassign_transactions_to_default_category, if: -> { sub_account.present? }

  private

  ### CALLBACKS ###

  # Prevent deletion of the default category
  def prevent_default_category_deletion
    errors.add(:base, "Cannot delete the default category. Assign a new default category first.")
    throw :abort
  end

  # Reassign transactions to the default category before deletion
  def reassign_transactions_to_default_category
    default_category = sub_account.default_category
    transactions.update_all(category_id: default_category.id) if default_category && default_category != self
  end

  ### HELPERS ###

  # Check if the category is the default category for its sub-account
  def default_category?
    sub_account&.default_category_id == id
  end
end
