class SubAccount < ApplicationRecord
  # Callbacks
  after_create :deduct_percentage_from_main_account
  after_create :create_default_category
  after_update :adjust_main_account_percentage
  after_destroy :restore_main_account_percentage

  # Associations
  belongs_to :main_account
  belongs_to :default_category, class_name: 'Category', foreign_key: :default_category_id, optional: true
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0 }
  validate :cannot_exceed_main_account_available_percentage, if: :new_or_updated_sub_account?

  private

  ### CALLBACKS ###

  def deduct_percentage_from_main_account
    main_account.update!(available_percentage: main_account.available_percentage - percentage)
  end

  def adjust_main_account_percentage
    return unless percentage_previously_changed?

    difference = percentage - percentage_before_last_save
    main_account.update!(available_percentage: main_account.available_percentage - difference)
    adjust_balance_from_percentage_change(difference)
  end

  def restore_main_account_percentage
    main_account.update!(available_percentage: main_account.available_percentage + percentage)
  end

  def create_default_category
    default_category = categories.create!(title: title)
    update!(default_category: default_category)
  end

  ### VALIDATIONS ###

  def cannot_exceed_main_account_available_percentage
    if percentage > main_account.available_percentage
      errors.add(:percentage, "cannot exceed the available percentage in the Main Account.")
    end
  end

  def new_or_updated_sub_account?
    will_save_change_to_percentage? || new_record?
  end

  ### HELPERS ###

  def adjust_balance_from_percentage_change(difference)
    delta = (difference / 100.0) * main_account.balance
    # Incrementally adjust the balance without overriding
    update_column(:balance, balance + delta)
  end
end
