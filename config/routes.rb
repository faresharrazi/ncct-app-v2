Rails.application.routes.draw do
  root "pages#home"
  get "pages/about"
  devise_for :users
end
