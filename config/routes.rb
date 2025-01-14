Rails.application.routes.draw do
  get "main_transactions/index"
  get "main_transactions/show"
  get "main_transactions/new"
  get "main_transactions/edit"
  root "pages#home"
  
  get "pages/about"
  devise_for :users

  resources :main_accounts do
    resources :main_transactions
    resources :sub_accounts do
      resources :sub_account_transactions
      resources :categories
    end
    resources :shared_main_account_users
  end
end
