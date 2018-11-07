# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [:sessions]
  as :user do
    delete "users/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  resources :services, only: [:index, :show] do
    scope module: :services do
      resources :offers, only: :index
      resource :offers, only: :update
      resource :configuration, only: [:show, :update]
      resource :summary, only: [:show, :create]
      resource :cancel, only: :destroy
      resource :questions, only: [:create]
      resources :opinions, only: :index
    end
  end

  resources :categories, only: :show

  resources :projects, only: [:index, :new, :create]
  resources :project_items, only: :show do
    scope module: :project_items do
      resources :questions, only: [:index, :create]
      resources :service_opinions, only: [:new, :create]
    end
  end

  resource :profile, only: [:show] do
    scope module: :profiles do
      resources :affiliations, only: [:new, :create, :edit, :update, :destroy]
    end
  end
  resources :affiliation_confirmations, only: :index

  resource :profile, only: :show

  resource :backoffice, only: :show
  namespace :backoffice do
    resources :services
  end

  namespace :api do
    namespace :webhooks do
      post "/jira" => "jiras#create", as: :jira
    end
  end

  if Rails.env.development?
    get "playground/:file" => "playground#show",
        constraints: { file: %r{[^/\.]+} }
  end

  resource :admin, only: :show
  namespace :admin do
    resources :jobs, only: :index
  end
  # Sidekiq monitoring
  authenticate :user, ->(u) { u.admin? } do
    require "sidekiq/web"
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  root "home#index"
end
