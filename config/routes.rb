Rails.application.routes.draw do
  resources :accounts, only: [:create]
end
