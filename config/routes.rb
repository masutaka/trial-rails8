require "sidekiq/web"

Rails.application.routes.draw do
  root "welcome#index"

  # 認証
  resource :session
  resources :passwords, param: :token

  # ユーザー
  resources :users, only: [ :show ], param: :username do
    resource :follow, only: [ :create, :destroy ]
    member do
      get :following
      get :followers
    end
  end

  # コンテンツ
  resources :posts, param: :slug do
    resources :comments, only: [ :create, :edit, :update, :destroy ], shallow: true
  end

  # プロダクト
  resources :products do
    resources :subscribers, only: [ :create ]
  end
  resource :unsubscribe, only: [ :show ]

  # 通知
  resources :notifications, only: [] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # その他
  get "chat", to: "chat#index"

  # システム
  get "up" => "rails/health#show", as: :rails_health_check
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
