class SharedMainAccountUser < ApplicationRecord
  belongs_to :user
  belongs_to :main_account
  
  validates :user_id, uniqueness: { scope: :main_account_id }

end
