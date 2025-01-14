class SubAccountTransaction < ApplicationRecord
  TRANSACTION_KINDS = %w[expense income].freeze

  # Associations
  belongs_to :sub_account
  belongs_to :creator, class_name: 'User'

  # Validations
  validates :title, :amount, :transaction_kind, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_kind, inclusion: { in: TRANSACTION_KINDS }
  validate :cannot_exceed_sub_account_balance, if: -> { expense_transaction? }

  # Callbacks
  after_create :adjust_balances_after_create
  before_update :adjust_balances_before_update
  before_destroy :reverse_balances_on_destroy

  private

  ### CALLBACKS ###

  def adjust_balances_after_create
    delta = income_transaction? ? amount : -amount
    adjust_account_balances(delta)
  end

  def adjust_balances_before_update
    previous_delta = income_transaction? ? -amount_before_last_save : amount_before_last_save
    new_delta = income_transaction? ? amount : -amount
    adjust_account_balances(previous_delta + new_delta)
  end

  def reverse_balances_on_destroy
    delta = income_transaction? ? -amount : amount
    adjust_account_balances(delta)
  end

  def adjust_account_balances(delta)
    # Adjust SubAccount balance
    sub_account.update!(balance: sub_account.balance + delta)

    # Adjust MainAccount balance
    sub_account.main_account.update!(balance: sub_account.main_account.balance + delta)
  end

  ### VALIDATIONS ###

  def cannot_exceed_sub_account_balance
    if amount > sub_account.balance
      errors.add(:amount, "cannot exceed the SubAccount's current balance (#{sub_account.balance}).")
    end
  end

  ### HELPERS ###

  def income_transaction?
    transaction_kind == 'income'
  end

  def expense_transaction?
    transaction_kind == 'expense'
  end
end
