class MainTransaction < ApplicationRecord
  TRANSACTION_KINDS = %w[income expense].freeze

  # Associations
  belongs_to :main_account
  belongs_to :creator, class_name: 'User'

  # Validations
  validates :title, :amount, :transaction_kind, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_kind, inclusion: { in: TRANSACTION_KINDS }

  # Callbacks
  after_create :adjust_balances_after_create
  before_update :adjust_balances_before_update
  before_destroy :reverse_balances_on_destroy

  private

  def adjust_balances_after_create
    delta = transaction_kind == 'income' ? amount : -amount
    adjust_main_account_balance(delta)
    distribute_amount_among_subaccounts(delta)
  end

  def adjust_balances_before_update
    previous_delta = transaction_kind == 'income' ? -amount_was : amount_was
    new_delta = transaction_kind == 'income' ? amount : -amount
    adjust_main_account_balance(new_delta - previous_delta)
    distribute_amount_among_subaccounts(new_delta - previous_delta)
  end

  def reverse_balances_on_destroy
    delta = transaction_kind == 'income' ? -amount : amount
    adjust_main_account_balance(delta)
    distribute_amount_among_subaccounts(delta)
  end

  def distribute_amount_among_subaccounts(delta)
    main_account.sub_accounts.each do |sub_account|
      allocated_amount = (sub_account.percentage / 100.0) * delta
      sub_account.update!(balance: sub_account.balance + allocated_amount)
    end

    leftover_percentage = main_account.available_percentage
    if leftover_percentage > 0
      leftover_amount = (leftover_percentage / 100.0) * delta
      main_account.update!(shareable_balance: main_account.shareable_balance + leftover_amount)
    end
  end

  def adjust_main_account_balance(delta)
    main_account.update!(balance: main_account.balance + delta)
  end
end