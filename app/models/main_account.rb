class MainAccount < ApplicationRecord
  # Callbacks
  after_save :adjust_sub_account_balances, if: :saved_change_to_balance?

  # Associations
  belongs_to :owner, class_name: 'User'
  has_many :sub_accounts, dependent: :destroy
  has_many :main_transactions, dependent: :destroy
  has_many :shared_main_account_users, dependent: :destroy
  has_many :partners, through: :shared_main_account_users, source: :user

  # Validations
  validates :title, presence: true
  validates :available_percentage, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  # Methods

  # Calculate the total balance (includes subaccount contributions)
  def calculate_balance
    main_incomes = main_transactions.where(transaction_kind: "income").sum(:amount)
    main_expenses = main_transactions.where(transaction_kind: "expense").sum(:amount)
    subaccount_incomes = sub_accounts.joins(:transactions).where(transactions: { transaction_kind: "income" }).sum(:amount)
    subaccount_expenses = sub_accounts.joins(:transactions).where(transactions: { transaction_kind: "expense" }).sum(:amount)

    main_incomes + subaccount_incomes - (main_expenses + subaccount_expenses)
  end

  # Calculate shareable balance (excludes subaccount contributions)
  def calculate_shareable_balance
    main_incomes = main_transactions.where(transaction_kind: "income").sum(:amount)
    main_expenses = main_transactions.where(transaction_kind: "expense").sum(:amount)
    subaccount_expenses = sub_accounts.joins(:transactions).where(transactions: { transaction_kind: "expense" }).sum(:amount)

    main_incomes - (main_expenses + subaccount_expenses)
  end

  # Update balances
  def update_balances!
    self.balance = calculate_balance
    self.shareable_balance = calculate_shareable_balance
    save!
  end

  private

  ### CALLBACKS ###

  # Adjust sub-account balances proportionally when the main account balance changes
  def adjust_sub_account_balances
    return if sub_accounts.empty?

    # Calculate the delta caused by a change in the main account balance
    delta = saved_change_to_balance[1] - saved_change_to_balance[0]

    sub_accounts.each do |sub_account|
      # Adjust each sub-account balance proportionally based on its percentage
      sub_delta = (sub_account.percentage / 100.0) * delta
      sub_account.update_column(:balance, sub_account.balance + sub_delta)
    end
  end
end
