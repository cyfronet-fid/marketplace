# frozen_string_literal: true

Rails.application.routes.draw do
  ############################## IMPORTANT!!! ################################
  # !!! Code of high security risk impact !!!
  # AAI service authentication is skipped for tests purpose
  get "users/login" => "users/auth_mock#login" if Rails.env.development? && Mp::Application.config.auth_mock
  #############################################################################

  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" },
             skip: [:sessions]
  as :user do
    delete "users/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
  get "/robots.txt" => "home#robots"
  post "user_action", to: "user_action#create"

  resources :services, only: %i[index show], constraints: { id: %r{[^/]+} } do
    scope module: :services do
      resource :offers, only: %i[show update]
      resource :configuration, only: %i[show update]
      resource :information, only: %i[show update]
      resource :summary, only: %i[show create]
      resource :cancel, only: :destroy
      resource :question, only: %i[new create], constraints: ->(req) { req.format == :js }
      resources :opinions, only: :index
      resources :details, only: :index
      resource :ordering_configuration, only: :show do
        scope module: :ordering_configuration do
          resources :offers, only: %i[new edit create update destroy]
        end
      end
    end
  end

  resource :comparisons, only: %i[show destroy] do
    scope module: :comparisons do
      resource :services, only: %i[create destroy]
    end
  end

  get "services/c/:category_id" => "services#index", as: :category_services
  resources :categories, only: :show

  resource :reports, only: %i[new create], constraints: ->(req) { req.format == :js }

  resources :projects do
    scope module: :projects do
      resource :add, only: :create
      resource :archive, only: :create
      resources :about, only: :index
      resources :services, only: %i[show index] do
        scope module: :services do
          resource :opinion, only: %i[new create]
          resource :conversation, only: %i[show create]
          resource :timeline, only: :show
        end
      end
      resource :conversation, only: %i[show create]
    end
  end

  resource :profile, only: %i[show edit update destroy]

  resources :providers, only: %i[index show] do
    scope module: :providers do
      resource :question, only: %i[new create], constraints: ->(req) { req.format == :js }
      resources :details, only: :index
    end
  end

  resources :favourites, only: :index
  post "favourites/services", to: "favourites/services#update"

  resource :help, only: :show

  resource :backoffice, only: :show
  namespace :backoffice do
    resources :services, constraints: { id: %r{[^/]+} } do
      scope module: :services do
        resource :logo_preview, only: :show
        resources :offers
        resource :publish, only: :create
        resource :draft, only: :create
      end
    end
    get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
    get "services/c/:category_id" => "services#index", as: :category_services
    resources :scientific_domains
    resources :categories
    resources :providers
    resources :platforms
    get "vocabularies", to: "vocabularies#index", type: "target_user", as: :vocabularies
    scope "/vocabularies" do
      resources :target_users, controller: "vocabularies", type: "target_user"
      resources :trls, controller: "vocabularies", type: "trl"
      resources :access_types, controller: "vocabularies", type: "access_type"
      resources :access_modes, controller: "vocabularies", type: "access_mode"
      resources :funding_bodies, controller: "vocabularies", type: "funding_body"
      resources :funding_programs, controller: "vocabularies", type: "funding_program"
      resources :life_cycle_statuses, controller: "vocabularies", type: "life_cycle_status"
      resources :provider_life_cycle_statuses, controller: "vocabularies", type: "provider_life_cycle_status"
      resources :areas_of_activity, controller: "vocabularies", type: "area_of_activity"
      resources :esfri_types, controller: "vocabularies", type: "esfri_type"
      resources :esfri_domains, controller: "vocabularies", type: "esfri_domain"
      resources :legal_statuses, controller: "vocabularies", type: "legal_status"
      resources :networks, controller: "vocabularies", type: "network"
      resources :societal_grand_challenges, controller: "vocabularies", type: "societal_grand_challenge"
      resources :structure_types, controller: "vocabularies", type: "structure_type"
      resources :meril_scientific_domains, controller: "vocabularies", type: "meril_scientific_domain"
    end
  end

  resource :executive, only: :show
  namespace :executive do
    resources :statistics, only: :index
  end

  mount Rswag::Ui::Engine => "/api_docs/swagger"
  mount Rswag::Api::Engine => "/api_docs/swagger"

  namespace :api do
    get "/services" => "services#index", defaults: { format: :json }, as: :services_api
    namespace :webhooks do
      post "/jira" => "jiras#create", as: :jira
    end

    namespace :v1 do
      resources :resources, only: %i[index show], constraints: { id: %r{[^/]+} } do
        resources :offers, only: %i[index create show destroy update], module: :resources
      end
      resources :oms, controller: :omses, only: %i[index show update] do
        resources :events, only: :index, module: :omses
        resources :messages, only: %i[index show create update], module: :omses
        resources :projects, only: %i[index show update], module: :omses do
          resources :project_items, only: %i[index show update], module: :projects
        end
      end
    end
  end

  resource :api_docs, only: %i[show create]

  resource :admin, only: :show
  namespace :admin do
    resources :jobs, only: :index
    resource :help, only: :show
    resources :help_sections, except: %i[index show]
    resources :help_items, except: %i[index show]
    resource :features, only: [:show]
    resources :tour_feedbacks, except: %i[update destroy]
    post "features/enable_modal"
    post "features/disable_modal"
    resources :lead_sections, except: :show
    resources :leads, except: :show
    resource :ab_tests, only: :show
  end

  # Sidekiq monitoring and split dashboard
  authenticate :user, ->(u) { u.admin? } do
    require "sidekiq/web"
    mount Sidekiq::Web => "/admin/sidekiq"
    mount Split::Dashboard, at: "/admin/split"
  end

  resource :tour_histories, only: :create
  resource :tour_feedbacks, only: :create

  direct :overview_tour_first_service do |params|
    service = Service.where(status: %i[published unverified errored]).order(:name).first
    service_path(service, params)
  end

  get "errors/not_found"
  get "errors/unprocessable"
  get "errors/internal_server_error"
  get "about", to: "pages#about", as: :about
  get "target_users", to: "pages#target_users", as: :target_users
  get "communities", to: "pages#communities", as: :communities
  get "about_projects", to: "pages#about_projects", as: :about_projects

  if Rails.env.development?
    get "designsystem" => "designsystem#index"
    get "designsystem/:file" => "designsystem#show",
        constraints: { file: %r{[^/.]+} }
  end

  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  root "home#index"
end
