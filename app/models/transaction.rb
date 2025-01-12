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
  before_validation :assign_default_category
  after_create :process_after_create
  after_destroy :process_after_destroy
  before_update :process_before_update, if: :transaction_changed?

  private

  ### VALIDATIONS ###

  def exactly_one_account_must_be_present
    if sub_account_id.blank? && main_account_id.blank?
      errors.add(:base, "Transaction must belong to either a SubAccount or a MainAccount.")
    elsif sub_account_id.present? && main_account_id.present?
      errors.add(:base, "Transaction cannot belong to both a SubAccount and a MainAccount.")
    end
  end

  def cannot_exceed_sub_account_balance
    if amount > sub_account.balance
      errors.add(:amount, "cannot exceed the SubAccount's current balance (#{sub_account.balance}).")
    end
  end

  ### CALLBACKS ###

  def assign_default_category
    if sub_account&.default_category && category.nil?
      # Assign the default category for the SubAccount
      self.category = sub_account.default_category
    elsif main_account && category.nil?
      # Assign a global category (Income or Expense) for MainAccount transactions
      self.category = Category.find_or_create_by!(
        title: transaction_kind.capitalize,
        sub_account_id: nil # Global category
      )
    end
  end

  def process_after_create
    if sub_account.present?
      adjust_account_balance(sub_account, -amount)
      adjust_account_balance(sub_account.main_account, -amount)
    elsif main_account.present? && income_transaction?
      adjust_account_balance(main_account, amount)
      distribute_to_sub_accounts(amount)
    end
  end

  def process_after_destroy
    if sub_account.present?
      adjust_account_balance(sub_account, amount)
      adjust_account_balance(sub_account.main_account, amount)
    elsif main_account.present? && income_transaction?
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

    main_account.sub_accounts.each do |sub|
      sub_delta = (sub.percentage / 100.0) * amount_delta
      sub.update_column(:balance, sub.balance + sub_delta)
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

  def income_transaction?
    transaction_kind == 'income'
  end

  def expense_transaction?
    transaction_kind == 'expense'
  end
end
