Rails.application.routes.draw do
  # 認証
  get "login",  to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout
  get  "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure", to: "sessions#failure"

  if Rails.env.development? || Rails.env.test?
    post "dev_login", to: "sessions#dev_create", as: :dev_login
  end

  # ダッシュボード
  root "dashboard#index"

  # 台帳
  resources :saases do
    collection do
      post :import
    end
  end
  resources :saas_accounts, except: [ :show ] do
    collection do
      post :import
    end
  end
  resources :users, only: [ :index, :show, :edit, :update ]

  # サーベイ
  resources :surveys, only: [ :index, :new, :create, :show ] do
    member do
      patch :close
      post :activate
      post :remind
    end
  end
  resources :survey_responses, only: [ :update ]

  # タスク管理
  resources :task_presets
  resources :tasks, only: [ :index, :new, :create, :show ]
  resources :task_items, only: [ :update ]

  # 申請・承認
  resources :approval_requests, only: [ :index, :new, :create, :show ] do
    member do
      post :approve
      post :reject
    end
  end

  # 管理者
  namespace :admin do
    resources :batches, only: [ :index ] do
      collection do
        post :sync_entra_users
        post :detect_retired_accounts
      end
    end
    resources :audit_logs, only: [ :index, :show ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
