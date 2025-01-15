class MainTransaction < ApplicationRecord
  TRANSACTION_KINDS = %w[income expense].freeze

  # Associations
  belongs_to :main_account

  # Validations
  validates :title, :amount, :transaction_kind, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_kind, inclusion: { in: TRANSACTION_KINDS }
  validate :sufficient_balance_for_expense, if: -> { transaction_kind == "expense" }

  # Callbacks
  after_create :adjust_main_account_balance_on_create
  before_update :adjust_main_account_balance_on_update
  before_destroy :adjust_main_account_balance_on_destroy

  private

  ### CALLBACKS ###

  def adjust_main_account_balance_on_create
    delta = transaction_kind == "income" ? amount : -amount
    main_account.update!(balance: main_account.balance + delta)
    distribute_amount_among_subaccounts(delta)
  end

  def adjust_main_account_balance_on_update
    # Reverse the effect of the old transaction
    old_delta = transaction_kind_was == "income" ? amount_was : -amount_was
    main_account.update!(balance: main_account.balance - old_delta)
    distribute_amount_among_subaccounts(-old_delta)

    # Apply the effect of the updated transaction
    new_delta = transaction_kind == "income" ? amount : -amount
    main_account.update!(balance: main_account.balance + new_delta)
    distribute_amount_among_subaccounts(new_delta)
  end

  def adjust_main_account_balance_on_destroy
    delta = transaction_kind == "income" ? amount : -amount
    main_account.update!(balance: main_account.balance - delta)
    distribute_amount_among_subaccounts(-delta)
  end

  def distribute_amount_among_subaccounts(delta)
    main_account.sub_accounts.each do |sub_account|
      sub_delta = (sub_account.percentage / 100.0) * delta
      sub_account.update_column(:balance, sub_account.balance + sub_delta)
    end
  end

  ### VALIDATIONS ###

  def sufficient_balance_for_expense
    if transaction_kind == "expense" && amount > main_account.balance
      errors.add(:amount, "cannot exceed the available balance in the Main Account.")
    end
  end
end