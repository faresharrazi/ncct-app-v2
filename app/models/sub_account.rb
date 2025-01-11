class SubAccount < ApplicationRecord

  before_create :build_default_category_record

  belongs_to :main_account
  belongs_to :default_category, 
             class_name: 'Category',
             foreign_key: :default_category_id,
             optional: true

  has_many :categories, dependent: :destroy
  has_many :transactions

  validates :title, presence: true
  validates :percentage, numericality: { greater_than: 0 }
  validate :cannot_exceed_main_account_available_percentage

  private

  def build_default_category_record
    cat = categories.build(
      title: title,
      description: "Default category for #{title}"
    )
    self.default_category = cat
  end

  def cannot_exceed_main_account_available_percentage
    sum_of_other_subaccounts = main_account.sub_accounts.where.not(id: id).sum(:percentage)
    total_percentage = sum_of_other_subaccounts + percentage

    if total_percentage > 100
      errors.add(:percentage, "exceeds the remaining available percentage in Main Account")
    end
  end
  
end
