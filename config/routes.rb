Rails.application.routes.draw do
  root 'metadata#stats'

  resources :accounts, only: [] do
    collection do
      post :import
      post :create if Rails.application.config.features[:signup]
      get :available if Rails.application.config.features[:signup]
    end
    member do
      delete :destroy
      match :lock, via: [:put, :patch]
      match :unlock, via: [:put, :patch]
      match :expire_password, via: [:put, :patch]
    end
  end

  resource :sessions, only: [:create] do
    get :refresh
    get :logout, action: 'destroy'
  end

  get '/password/reset' => 'passwords#edit'
  post '/password' => 'passwords#update'

  # NOTE: this does not use .well-known/openid-configuration because this service does
  #       not fully conform to the openid-connect spec.
  get '/configuration' => 'metadata#configuration', as: 'app_configuration'
  get '/jwks' => 'metadata#keys', as: 'app_keys'

  get '/stats' => 'metadata#stats', as: 'app_stats'
end
