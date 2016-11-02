Rails.application.routes.draw do
  resources :accounts, only: [:create] do
    get :available, on: :collection
    patch :confirm, on: :member
  end
end
