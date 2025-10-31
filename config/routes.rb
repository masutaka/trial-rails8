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

  scope :notifications do
    patch ":id/mark_as_read", to: "notifications#mark_as_read", as: :mark_as_read_notification
    patch "mark_all_as_read", to: "notifications#mark_all_as_read", as: :mark_all_as_read_notifications
  end

  get "chat", to: "chat#index"

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
