Rails.application.routes.draw do
  resources :accounts, only: [:create] do
    get :available, on: :collection
  end

  resources :sessions, only: [:create]
end
