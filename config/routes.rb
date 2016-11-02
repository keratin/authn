Rails.application.routes.draw do
  resources :accounts, only: [:create] do
    patch :confirm, on: :member
  end
end
