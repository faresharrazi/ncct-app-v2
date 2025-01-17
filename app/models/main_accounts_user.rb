class MainAccountsUser < ApplicationRecord
  belongs_to :user
  belongs_to :main_account
end
