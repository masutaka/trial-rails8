require "sidekiq/web"

Rails.application.routes.draw do
  root "welcome#index"

  resources :users, only: [ :show ], param: :username do
    resource :follow, only: [ :create, :destroy ]
    member do
      get :following
      get :followers
    end
  end

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  resources :products do
    resources :subscribers, only: [ :create ]
  end

  resource :unsubscribe, only: [ :show ]

  resources :posts, param: :slug do
    resources :comments, only: [ :create, :edit, :update, :destroy ], shallow: true
  end

  resources :notifications, only: [] do
    member do
      patch :mark_as_read
    end

    collection do
      patch :mark_all_as_read
    end
  end

  get "chat", to: "chat#index"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
