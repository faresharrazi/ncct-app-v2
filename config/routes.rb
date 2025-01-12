Rails.application.routes.draw do
  root "pages#home"
  get "pages/about"
  devise_for :users

  resources :transactions, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :main_accounts do
    resources :sub_accounts do
      resources :categories
    end
    resources :shared_main_account_users, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end
end