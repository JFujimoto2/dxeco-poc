Rails.application.routes.draw do
  # 認証
  get  "login",  to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout
  get  "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure", to: "sessions#failure"

  if Rails.env.development? || Rails.env.test?
    post "dev_login", to: "sessions#dev_create", as: :dev_login
  end

  # ダッシュボード
  root "dashboard#index"

  # 台帳
  resources :saases
  resources :saas_accounts, except: [:show]
  resources :users, only: [:index, :show, :edit, :update]

  get "up" => "rails/health#show", as: :rails_health_check
end
