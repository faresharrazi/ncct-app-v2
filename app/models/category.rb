class Category < ApplicationRecord

  before_destroy :check_if_default
  before_destroy :reassign_transactions_to_default

  belongs_to :sub_account
  has_many :transactions

  validates :title, presence: true

  private

  def check_if_default
    if sub_account.default_category_id == id
      errors.add(:base, "Cannot delete the default category. Assign a new default category first.")
      throw :abort
    end
  end

  def reassign_transactions_to_default
    default_cat = sub_account.default_category
    return unless default_cat.present? && default_cat != self
    transactions.update_all(category_id: default_cat.id)
  end
  
end
