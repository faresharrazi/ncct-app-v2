class SubAccount < ApplicationRecord
  # Associations
  belongs_to :main_account
  has_many :transactions, class_name: 'SubAccountTransaction', dependent: :destroy

  # Callbacks
  after_create :deduct_percentage_from_main_account, :initialize_balance_from_shareable_balance
  after_update :adjust_main_account_percentage
  after_destroy :restore_main_account_resources

  # Validations
  validates :title, presence: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0 }

  private

  ### CALLBACKS ###

  def deduct_percentage_from_main_account
    main_account.update!(
      available_percentage: main_account.available_percentage - percentage,
      shareable_balance: main_account.shareable_balance - balance
    )
  end

  def initialize_balance_from_shareable_balance
    calculated_balance = (percentage / 100.0) * main_account.shareable_balance
    update_column(:balance, calculated_balance)
  end

  def adjust_main_account_percentage
    return unless percentage_previously_changed?

    difference = percentage - percentage_before_last_save
    main_account.update!(
      available_percentage: main_account.available_percentage - difference
    )
  end

  def restore_main_account_resources
    new_available_percentage = main_account.available_percentage + percentage
    new_shareable_balance = main_account.shareable_balance + balance

    # Ensure available_percentage does not exceed 100
    main_account.update!(
      available_percentage: [new_available_percentage, 100].min,
      shareable_balance: new_shareable_balance
    )
  end
end
