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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

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

  # Sidekiq Web UI (development only)
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
