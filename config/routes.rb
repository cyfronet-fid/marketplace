# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [:sessions]
  as :user do
    delete "users/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  resource :cart, only: :create

  resources :services, only: [:index, :show]
  resources :categories, only: :show
  resources :orders, only: [:index, :show, :new, :create] do
    scope module: :orders do
      resources :questions, only: [:index, :create]
      resources :service_opinions, only: [:new, :create]
    end
  end

  resources :providers, only: :show

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

  root "home#index"
end
