class SubAccount < ApplicationRecord
  belongs_to :main_account
  has_many :sub_account_transactions, dependent: :destroy
  has_many :categories, dependent: :destroy

  validates :title, presence: true, uniqueness: { scope: :main_account_id, message: "Account title should be unique" }  
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  after_create :initialize_balance_from_shareable_balance
  after_create :create_default_category
  after_update :adjust_main_account_percentage
  after_destroy :restore_main_account_resources

  private

  ### CALLBACKS ###

  def create_default_category
    categories.create(title: title, description: "Default Category")
  end

  def initialize_balance_from_shareable_balance
    shareable_balance = main_account.shareable_balance
    allocated_balance = (percentage / 100.0) * shareable_balance

    update!(balance: allocated_balance)
    main_account.update_shareable_balance(-allocated_balance)
    main_account.update!(available_percentage: main_account.available_percentage - percentage)
  end

  def adjust_main_account_percentage
    return unless percentage_previously_changed?

    difference = percentage - percentage_before_last_save
    new_balance = (percentage / 100.0) * main_account.shareable_balance

    update!(balance: new_balance)
    main_account.update!(
      available_percentage: main_account.available_percentage - difference,
      shareable_balance: main_account.shareable_balance - new_balance
    )
  end

  def restore_main_account_resources
    main_account.update!(
      available_percentage: main_account.available_percentage + percentage,
      shareable_balance: main_account.shareable_balance + balance
    )
  end
end