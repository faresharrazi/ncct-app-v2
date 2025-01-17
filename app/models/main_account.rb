class MainAccount < ApplicationRecord
  has_and_belongs_to_many :owners, class_name: 'User', join_table: 'main_accounts_users'
  has_many :sub_accounts, dependent: :destroy
  has_many :main_transactions, dependent: :destroy
  has_many :shared_main_account_users, dependent: :destroy
  has_many :users, through: :shared_main_account_users

  validates :title, :currency, presence: true

  def calculate_balance
    main_incomes = main_transactions.where(transaction_kind: "income").sum(:amount)
    main_expenses = main_transactions.where(transaction_kind: "expense").sum(:amount)
    subaccount_incomes = sub_accounts.joins(:sub_account_transactions).where(sub_account_transactions: { transaction_kind: "income" }).sum(:amount)
    subaccount_expenses = sub_accounts.joins(:sub_account_transactions).where(sub_account_transactions: { transaction_kind: "expense" }).sum(:amount)

    main_incomes + subaccount_incomes - (main_expenses + subaccount_expenses)
  end

  def shareable_balance
    main_incomes = main_transactions.where(transaction_kind: "income").sum(:amount)
    main_expenses = main_transactions.where(transaction_kind: "expense").sum(:amount)
    main_incomes - main_expenses
  end

  def available_percentage
    100 - sub_accounts.sum(:percentage)
  end

  def update_shareable_balance(amount)
    update!(shareable_balance: shareable_balance + amount)
  end

  def distribute_balance_among_subaccounts(delta)
    sub_accounts.each do |sub_account|
      allocated_amount = (sub_account.percentage / 100.0) * delta
      sub_account.update!(balance: sub_account.balance + allocated_amount)
    end

    leftover_percentage = available_percentage
    if leftover_percentage > 0
      leftover_amount = (leftover_percentage / 100.0) * delta
      update!(shareable_balance: shareable_balance + leftover_amount)
    end
  end
end