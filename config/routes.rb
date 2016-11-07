Rails.application.routes.draw do
  resources :accounts, only: [:create] do
    get :available, on: :collection
  end

  resources :sessions, only: [:create]

  # NOTE: this does not use .well-known/openid-configuration because this service does
  #       not fully conform to the openid-connect spec.
  get '/configuration' => 'application#configuration', as: 'app_configuration'
  get '/jwks' => 'application#keys', as: 'app_keys'
end
