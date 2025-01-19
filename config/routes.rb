Rails.application.routes.draw do
  root "pages#home"
  get "pages/about"
  get "settings", to: "pages#settings", as: :settings
  devise_for :users

  resources :main_accounts do
    member do
      post 'leave'
      post 'switch'
    end
    resources :main_transactions do
      member do
        post 'repeat_without_edit'
      end
    end
    resources :sub_accounts do
      resources :sub_account_transactions do
        member do
          post 'repeat_without_edit'
        end
      end
      resources :categories, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    end
    resources :shared_main_account_users do
      collection do
        get :search
      end
      member do
        delete :remove
      end
    end
  end
  
  post 'accept_invitation/:id', to: 'shared_main_account_users#accept_invitation', as: :accept_invitation
  delete 'cancel_invitation/:main_account_id/:id', to: 'shared_main_account_users#destroy', as: :cancel_invitation  
  delete 'reject_invitation/:id', to: 'shared_main_account_users#reject_invitation', as: :reject_invitation

  # Custom route to show all subaccount transactions
  get 'sub_account_transactions', to: 'sub_account_transactions#all', as: :all_sub_account_transactions
  
  # Custom route to create a new subaccount transaction without specifying the subaccount
  get 'sub_account_transactions/new', to: 'sub_account_transactions#new_without_subaccount', as: :new_sub_account_transaction_without_subaccount
  post 'sub_account_transactions', to: 'sub_account_transactions#create', as: :create_sub_account_transaction_without_subaccount

  # Custom route to fetch the balance of a specific subaccount
  get 'sub_accounts/:id/balance', to: 'sub_accounts#balance', as: :sub_account_balance

  # Custom route to fetch categories for a specific subaccount
  get 'sub_accounts/:sub_account_id/categories', to: 'categories#index', as: :sub_account_categories
end