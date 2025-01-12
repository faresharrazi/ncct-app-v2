# app/models/transaction.rb
class Transaction < ApplicationRecord

  TRANSACTION_KINDS = %w[expense income].freeze

  after_create  :handle_after_create
  after_destroy :handle_after_destroy
  before_update :handle_before_update, if: :transaction_changed?

  belongs_to :main_account, optional: true
  belongs_to :sub_account,   optional: true
  belongs_to :category,      optional: true
  belongs_to :creator,       class_name: 'User'

  # Validations
  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_kind, presence: true, inclusion: { in: TRANSACTION_KINDS }
  validate :exactly_one_account_must_be_present
  validate :cannot_exceed_sub_account_balance, if: :expense_and_sub_account?

  # Scopes for filtering
  scope :expenses, -> { where(transaction_kind: 'expense') }
  scope :incomes, -> { where(transaction_kind: 'income') }

  private

  # Custom Validations
  def exactly_one_account_must_be_present
    if sub_account_id.blank? && main_account_id.blank?
      errors.add(:base, "Must belong to either a SubAccount or a MainAccount.")
    elsif sub_account_id.present? && main_account_id.present?
      errors.add(:base, "Cannot belong to both SubAccount and MainAccount at the same time.")
    end
  end

  def cannot_exceed_sub_account_balance
    if sub_account.present? && amount > sub_account.balance
      errors.add(:amount, "cannot exceed the subaccount's current balance (#{sub_account.balance})")
    end
  end

  def expense_and_sub_account?
    transaction_kind == 'expense' && sub_account_id.present?
  end

  # Callback Orchestration
  def handle_after_create
    if main_account_id.present?
      apply_main_account_transaction(amount_with_sign)
    else
      adjust_sub_account_balance(amount_with_sign)
      update_main_account_balance(sub_account.main_account)
    end
  end

  def handle_after_destroy
    if main_account_id.present?
      apply_main_account_transaction(-amount_with_sign)
    else
      adjust_sub_account_balance(-amount_with_sign)
      update_main_account_balance(sub_account.main_account)
    end
  end

  def handle_before_update
    old_amount = amount_before_last_save || amount_was
    old_kind = transaction_kind_before_last_save || transaction_kind_was
    old_sign = old_kind == 'income' ? old_amount : -old_amount
    new_sign = amount_with_sign
    difference = new_sign - old_sign

    if main_account_id.present?
      apply_main_account_transaction(difference)
    else
      adjust_sub_account_balance(difference)
      update_main_account_balance(sub_account.main_account)
    end
  end

  # Helpers
  def amount_with_sign
    transaction_kind == 'income' ? amount : -amount
  end

  def apply_main_account_transaction(amount_delta)
    new_main_balance = main_account.balance + amount_delta
    main_account.update!(balance: new_main_balance)

    main_account.sub_accounts.find_each do |sub|
      sub_delta = (sub.percentage / 100.0) * amount_delta
      new_sub_balance = sub.balance + sub_delta
      sub.update!(balance: new_sub_balance)
    end
  end

  def adjust_sub_account_balance(value)
    new_balance = sub_account.balance + value
    sub_account.update!(balance: new_balance)
  end

  def update_main_account_balance(m_account)
    total_balance = m_account.sub_accounts.sum(:balance)
    m_account.update!(balance: total_balance)
  end

  def transaction_changed?
    will_save_change_to_amount? || will_save_change_to_transaction_kind?
  end
end
