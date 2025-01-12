class Transaction < ApplicationRecord
  TRANSACTION_KINDS = %w[expense income].freeze

  # Associations
  belongs_to :main_account, optional: true
  belongs_to :sub_account, optional: true
  belongs_to :category, optional: true
  belongs_to :creator, class_name: 'User'

  # Validations
  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, message: "must be greater than 0" }
  validates :transaction_kind, presence: true, inclusion: { in: TRANSACTION_KINDS }
  validate :exactly_one_account_must_be_present
  validate :cannot_exceed_sub_account_balance, if: -> { expense_transaction? && sub_account.present? }

  # Callbacks
  before_validation :assign_default_category, if: -> { category.nil? && sub_account.present? }
  after_create :process_after_create
  after_destroy :process_after_destroy
  before_update :process_before_update, if: :transaction_changed?

  # Scopes
  scope :expenses, -> { where(transaction_kind: 'expense') }
  scope :incomes, -> { where(transaction_kind: 'income') }

  private

  ### VALIDATIONS ###

  # Ensures transaction is tied to either a MainAccount or a SubAccount, but not both
  def exactly_one_account_must_be_present
    if sub_account_id.blank? && main_account_id.blank?
      errors.add(:base, "Transaction must belong to either a SubAccount or a MainAccount.")
    elsif sub_account_id.present? && main_account_id.present?
      errors.add(:base, "Transaction cannot belong to both a SubAccount and a MainAccount.")
    end
  end

  # Ensures expense transactions do not exceed the SubAccount balance
  def cannot_exceed_sub_account_balance
    if amount > sub_account.balance
      errors.add(:amount, "cannot exceed the SubAccount's current balance (#{sub_account.balance}).")
    end
  end

  # Checks if the transaction is an expense
  def expense_transaction?
    transaction_kind == 'expense'
  end

  ### CALLBACKS ###

  def assign_default_category
    if sub_account&.default_category
      self.category = sub_account.default_category
    elsif main_account
      self.category = nil # Main account transactions don't use sub-account categories
    end
  end

  def process_after_create
    if sub_account.present?
      # Deduct from SubAccount and MainAccount for expense
      adjust_account_balance(sub_account, -amount)
      adjust_account_balance(sub_account.main_account, -amount)
    elsif main_account.present? && income_transaction?
      # Add to MainAccount and distribute to SubAccounts for income
      adjust_account_balance(main_account, amount)
      distribute_to_sub_accounts(amount)
    end
  end

  def process_after_destroy
    if sub_account.present?
      # Reverse deduction from SubAccount and MainAccount
      adjust_account_balance(sub_account, amount)
      adjust_account_balance(sub_account.main_account, amount)
    elsif main_account.present? && income_transaction?
      # Reverse distribution to SubAccounts and MainAccount for income
      adjust_account_balance(main_account, -amount)
      distribute_to_sub_accounts(-amount)
    end
  end

  def process_before_update
    old_sign = old_transaction_sign
    new_sign = amount_with_sign
    difference = new_sign - old_sign

    if sub_account.present?
      adjust_account_balance(sub_account, -difference)
      adjust_account_balance(sub_account.main_account, -difference)
    elsif main_account.present? && income_transaction?
      adjust_account_balance(main_account, difference)
      distribute_to_sub_accounts(difference)
    end
  end

  ### BALANCE ADJUSTMENTS ###

  def adjust_account_balance(account, amount_delta)
    account.update!(balance: account.balance + amount_delta)
  end

  def distribute_to_sub_accounts(amount_delta)
    return unless main_account

    Rails.logger.debug "Distributing #{amount_delta} to subaccounts of main_account #{main_account.id}"

    main_account.sub_accounts.each do |sub|
      sub_delta = (sub.percentage / 100.0) * amount_delta
      new_sub_balance = sub.balance + sub_delta

      # Update balance directly
      sub.update_column(:balance, new_sub_balance)
      Rails.logger.debug "SubAccount #{sub.id} updated successfully. New balance: #{new_sub_balance}"
    end
  end

  ### HELPERS ###

  def amount_with_sign
    transaction_kind == 'income' ? amount : -amount
  end

  def old_transaction_sign
    old_amount = amount_before_last_save || amount_was
    old_kind = transaction_kind_before_last_save || transaction_kind_was
    old_kind == 'income' ? old_amount : -old_amount
  end

  def transaction_changed?
    will_save_change_to_amount? || will_save_change_to_transaction_kind?
  end
end
