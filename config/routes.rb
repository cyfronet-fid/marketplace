# frozen_string_literal: true

Rails.application.routes.draw do

  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [:sessions]
  as :user do
    delete "users/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
  get "/robots.txt" => "home#robots"

  resources :services, only: [:index, :show] do
    scope module: :services do
      resource :offers, only: [:show, :update]
      resource :configuration, only: [:show, :update]
      resource :information, only: [:show, :update]
      resource :summary, only: [:show, :create]
      resource :cancel, only: :destroy
      resource :question, only: [:new, :create], constraints: lambda { |req| req.format == :js }
      resources :opinions, only: :index
    end
  end

  resource :comparisons, only: [:show, :destroy] do
    scope module: :comparisons do
      resource :services, only: [:create, :destroy]
    end
  end

  get "services/c/:category_id" => "services#index", as: :category_services
  resources :categories, only: :show

  resource :reports, only: [:new, :create], constraints: lambda { |req| req.format == :js }

  resources :projects do
    scope module: :projects do
      resource :add, only: :create
      resource :archive, only: :create
      resources :about, only: :index
      resources :services, only: [:show, :index] do
        scope module: :services do
          resource :opinion, only: [:new, :create]
          resource :conversation, only: [:show, :create]
          resource :timeline, only: :show
        end
      end
      resource :conversation, only: [:show, :create]
    end
  end

  patch "/profile", to: "users#update"
  scope module: :profile do
    resource :user, except: [:new, :create], path: "/profile"
    patch "/profile/:id", to: "users#update"
    delete "/profile/:id", to: "users#destroy"
  end
  resource :help, only: :show

  resource :backoffice, only: :show
  namespace :backoffice do
    resources :services do
      scope module: :services do
        resource :logo_preview, only: :show
        resources :offers
        resources :offers do
          scope module: :offers do
            resource :publish, only: :create
            resource :draft, only: :create
          end
        end
        resource :publish, only: :create
        resource :draft, only: :create
      end
    end
    get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
    get "services/c/:category_id" => "services#index", as: :category_services
    resources :research_areas
    resources :categories
    resources :providers
    resources :platforms
  end

  resource :executive, only: :show
  namespace :executive do
    resources :statistics, only: :index
  end

  namespace :api do
    get "/services" => "services#index", defaults: { format: :json }, as: :services_api
    namespace :webhooks do
      post "/jira" => "jiras#create", as: :jira
    end
  end

  resource :admin, only: :show
  namespace :admin do
    resources :jobs, only: :index
    resource :help, only: :show
    resources :help_sections, except: [:index, :show]
    resources :help_items, except: [:index, :show]
    resources :lead_sections, except: :show
    resources :leads, except: :show
  end

  # Sidekiq monitoring
  authenticate :user, ->(u) { u.admin? } do
    require "sidekiq/web"
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  get "errors/not_found"
  get "errors/unprocessable"
  get "errors/internal_server_error"
  match "about", to: "pages#about", via: "get", as: :about
  match "providers", to: "pages#providers", via: "get", as: :providers
  match "communities", to: "pages#communities", via: "get", as: :communities
  match "about_projects", to: "pages#about_projects", via: "get", as: :about_projects

  if Rails.env.production?
    match "/404", to: "errors#not_found", via: :all
    match "/422", to: "errors#unprocessable", via: :all
    match "/500", to: "errors#internal_server_error", via: :all
  end

  if Rails.env.development?
    get "designsystem" => "designsystem#index"
    get "designsystem/:file" => "designsystem#show",
      constraints: { file: %r{[^/\.]+} }
  end

  root "home#index"
end
