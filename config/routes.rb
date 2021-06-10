# frozen_string_literal: true

Rails.application.routes.draw do
  ############################## IMPORTANT!!! ################################
  # !!! Code of high security risk impact !!!
  # AAI service authentication is skipped for tests purpose
  if Rails.env.development? && Mp::Application.config.auth_mock
    get "users/login" => "users/auth_mock#login"
  end
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

  resources :services, only: [:index, :show], constraints: { id: /[^\/]+/ } do
    scope module: :services do
      resource :offers, only: [:show, :update]
      resource :configuration, only: [:show, :update]
      resource :information, only: [:show, :update]
      resource :summary, only: [:show, :create]
      resource :cancel, only: :destroy
      resource :question, only: [:new, :create], constraints: lambda { |req| req.format == :js }
      resources :opinions, only: :index
      resources :details, only: :index
      resource :ordering_configuration, only: :show do
        scope module: :ordering_configuration do
          resources :offers, only: [:new, :edit, :create, :update, :destroy]
        end
      end
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

  resource :profile, only: [:show, :edit, :update, :destroy]

  resources :providers, only: [:index, :show] do
    scope module: :providers do
      resource :question, only: [:new, :create], constraints: lambda { |req| req.format == :js }
      resources :details, only: :index
    end
  end

  resources :favourites, only: :index
  post "favourites/services", to: "favourites/services#update"

  resource :help, only: :show

  resource :backoffice, only: :show
  namespace :backoffice do
    resources :services, constraints: { id: /[^\/]+/ } do
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
    resources :scientific_domains
    resources :categories
    resources :providers
    resources :platforms
    get :vocabularies, to: "vocabularies/target_users#index", type: "TargetUser", as: :vocabularies
    scope "/vocabularies" do
      resources :target_users, controller: "vocabularies", type: "TargetUser"
      resources :trls, controller: "vocabularies", type: "Vocabulary::Trl"
      resources :access_types, controller: "vocabularies", type: "Vocabulary::AccessType"
      resources :access_modes, controller: "vocabularies", type: "Vocabulary::AccessMode"
      resources :funding_bodies, controller: "vocabularies", type: "Vocabulary::FundingBody"
      resources :funding_programs, controller: "vocabularies", type: "Vocabulary::FundingProgram"
      resources :life_cycle_statuses, controller: "vocabularies", type: "Vocabulary::LifeCycleStatus"
      resources :provider_life_cycle_statuses, controller: "vocabularies", type: "Vocabulary::ProviderLifeCycleStatus"
      resources :areas_of_activity, controller: "vocabularies", type: "Vocabulary::AreaOfActivity"
      resources :esfri_types, controller: "vocabularies", type: "Vocabulary::EsfriType"
      resources :esfri_domains, controller: "vocabularies", type: "Vocabulary::EsfriDomain"
      resources :legal_statuses, controller: "vocabularies", type: "Vocabulary::LegalStatus"
      resources :networks, controller: "vocabularies", type: "Vocabulary::Network"
      resources :societal_grand_challenges, controller: "vocabularies", type: "Vocabulary::SocietalGrandChallenge"
      resources :structure_types, controller: "vocabularies", type: "Vocabulary::StructureType"
      resources :meril_scientific_domains, controller: "vocabularies", type: "Vocabulary::MerilScientificDomain"
    end

  end

  resource :executive, only: :show
  namespace :executive do
    resources :statistics, only: :index
  end

  mount Rswag::Ui::Engine => '/api_docs/swagger'
  mount Rswag::Api::Engine => '/api_docs/swagger'

  namespace :api do
    get "/services" => "services#index", defaults: { format: :json }, as: :services_api
    namespace :webhooks do
      post "/jira" => "jiras#create", as: :jira
    end

    namespace :v1 do
      resources :resources, only: [:index, :show], constraints: { id: /[^\/]+/ } do
        resources :offers, only: [:index, :create, :show, :destroy, :update], module: :resources
      end
      resources :oms, controller: :omses, only: [:index, :show, :update] do
        resources :events, only: :index, module: :omses
        resources :messages, only: [:index, :show, :create, :update], module: :omses
        resources :projects, only: [:index, :show, :update], module: :omses do
          resources :project_items, only: [:index, :show, :update], module: :projects
        end
      end
    end
  end

  resource :api_docs, only: [:show, :create, :destroy]

  resource :admin, only: :show
  namespace :admin do
    resources :jobs, only: :index
    resource :help, only: :show
    resources :help_sections, except: [:index, :show]
    resources :help_items, except: [:index, :show]
    resource :features, only: [:show]
    resources :tour_feedbacks, except: [:update, :destroy]
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

  get "errors/not_found"
  get "errors/unprocessable"
  get "errors/internal_server_error"
  match "about", to: "pages#about", via: "get", as: :about
  match "target_users", to: "pages#target_users", via: "get", as: :target_users
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
