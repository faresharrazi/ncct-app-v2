class MainTransaction < ApplicationRecord
  TRANSACTION_KINDS = %w[income expense].freeze

  # Associations
  belongs_to :main_account

  # Validations
  validates :title, :amount, :transaction_kind, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :transaction_kind, inclusion: { in: TRANSACTION_KINDS }

  # Callbacks
  after_create :adjust_main_account_balance_and_distribute_to_sub_accounts

  private

  ### CALLBACKS ###

  def adjust_main_account_balance_and_distribute_to_sub_accounts
    # Adjust the main account balance
    delta = transaction_kind == "income" ? amount : -amount
    main_account.update!(balance: main_account.balance + delta)

    # Distribute the delta among sub-accounts based on their percentage
    distribute_to_sub_accounts(delta)
  end

  ### HELPERS ###

  def distribute_to_sub_accounts(delta)
    return unless main_account.sub_accounts.any?

    main_account.sub_accounts.each do |sub_account|
      # Calculate the portion of the delta based on the sub-account's percentage
      sub_delta = (sub_account.percentage / 100.0) * delta
      sub_account.update!(balance: sub_account.balance + sub_delta)
    end
  end
end
