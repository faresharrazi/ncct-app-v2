class SubAccount < ApplicationRecord
  after_create :deduct_percentage_from_main_account
  after_update :adjust_main_account_percentage
  after_destroy :restore_main_account_percentage

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

  def deduct_percentage_from_main_account
    main_account.update!(available_percentage: main_account.available_percentage - percentage)
  end

  def adjust_main_account_percentage
    return unless percentage_previously_changed?

    difference = percentage - percentage_before_last_save
    main_account.update!(available_percentage: main_account.available_percentage - difference)
  end

  def restore_main_account_percentage
    main_account.update!(available_percentage: main_account.available_percentage + percentage)
  end

  def cannot_exceed_main_account_available_percentage
    if percentage > main_account.available_percentage
      errors.add(:percentage, "cannot exceed the available percentage in the Main Account.")
    end
  end
end
