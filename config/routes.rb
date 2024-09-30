# frozen_string_literal: true

Rails.application.routes.draw do
  ############################## IMPORTANT!!! ################################
  # !!! Code of high security risk impact !!!
  # AAI service authentication is skipped for tests purpose
  get "users/login" => "users/auth_mock#login" if Rails.env.development? && Mp::Application.config.auth_mock

  #############################################################################

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:sessions]
  as :user do
    delete "users/logout", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
  get "ror_autocomplete", to: "rors#autocomplete", as: :ror_autocomplete
  get "rors", to: "rors#index", as: :rors
  get "/robots.txt" => "home#robots"
  post "user_action", to: "user_action#create"
  if ActiveModel::Type::Boolean.new.cast(ENV.fetch("MP_ENABLE_EXTERNAL_SEARCH", false))
    get "/", to: "pages#landing_page", as: :new_landing_page
  end
  get "/datasources/:id", to: redirect("/services/%{id}")
  get "backoffice/datasources/:id", to: redirect("backoffice/services/%{id}")

  resources :services, only: %i[index show], constraints: { id: %r{[^/]+} } do
    scope module: :services do
      resource :offers, only: %i[show update]
      resource :configuration, only: %i[show update]
      resource :information, only: %i[show update]
      resource :summary, only: %i[show create]
      resource :cancel, only: :destroy
      resource :logo, only: :show
      resource :question, only: %i[new create]
      resources :opinions, only: :index
      resources :details, only: :index
      resources :guidelines, only: :index
      resources :bundles, only: :show
      resource :ordering_configuration, only: :show do
        scope module: :ordering_configuration do
          resources :offers, only: %i[new edit create update destroy] do
            resource :publish, controller: "offers/publishes", only: :create
            resource :draft, controller: "offers/drafts", only: :create
          end
          resources :bundles, only: %i[new edit create update destroy] do
            resource :publish, controller: "bundles/publishes", only: :create
            resource :draft, controller: "bundles/drafts", only: :create
          end
        end
      end
    end
  end

  resource :comparisons, only: %i[show destroy] do
    scope module: :comparisons do
      resource :services, only: %i[create destroy]
    end
  end

  get "services/c/:category_id" => "services#index", :as => :category_services
  resources :categories, only: :show

  resources :catalogues, only: %i[index show] do
    scope module: :catalogues do
      resource :logo, only: :show
    end
  end

  resource :reports, only: %i[new create], constraints: lambda { |req| req.format == :js }

  resources :projects do
    scope module: :projects do
      resource :add, only: :create
      resource :archive, only: :create
      resources :about, only: :index
      resources :research_products, only: %i[show index destroy]
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

  resources :providers, only: %i[index show], constraints: { id: %r{[^/]+} } do
    scope module: :providers do
      resource :question, only: %i[new create]
      resources :details, only: :index
      resource :logo, only: :show
    end
  end

  resources :research_products, only: %i[new create]

  resources :favourites, only: :index
  post "favourites/services", to: "favourites/services#update"

  resource :help, only: :show, path: "user_documentation"

  resource :backoffice, only: :show
  namespace :backoffice do
    resources :services, controller: "services", constraints: { id: %r{[^/]+} } do
      scope module: :services do
        resource :logo_preview, only: :show
        resources :offers do
          resource :publish, controller: "offers/publishes", only: :create
          resource :draft, controller: "offers/drafts", only: :create
        end
        resources :bundles do
          resource :publish, controller: "bundles/publishes", only: :create
          resource :draft, controller: "bundles/drafts", only: :create
        end
        resource :publish, only: :create
        resource :draft, only: :create
      end
    end
    get "service_autocomplete", to: "services#autocomplete", as: :service_autocomplete
    get "services/c/:category_id" => "services#index", :as => :category_services
    resources :scientific_domains
    resources :categories
    resources :providers, constraints: { id: %r{[^/]+} }
    resources :catalogues
    resources :platforms
    get "vocabularies", to: "vocabularies#index", type: "target_user", as: :vocabularies
    scope "/vocabularies" do
      VOCABULARY_TYPES.each do |type, opts|
        resources opts[:route], controller: "vocabularies", type: type.to_s
      end
    end
  end

  post "/backoffice/services/:service_id/offers/fetch_subtypes", to: "backoffice/services/offers#fetch_subtypes"

  post "/backoffice/services/:service_id/offers/:offer_id/submit", to: "backoffice/services/offers#submit_summary"
  patch "/backoffice/services/:service_id/offers/:offer_id/submit", to: "backoffice/services/offers#submit_summary"

  resource :executive, only: :show
  namespace :executive do
    resources :statistics, only: :index
  end

  mount Rswag::Ui::Engine => "/api_docs/swagger"
  mount Rswag::Api::Engine => "/api_docs/swagger"

  namespace :api do
    get "/services" => "services#index", :defaults => { format: :json }, :as => :services_api
    namespace :webhooks do
      post "/jira" => "jiras#create", :as => :jira
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
      namespace :ess do
        resources :services, only: %i[index show], constraints: { id: %r{[^/]+} }
        resources :datasources, only: %i[index show], constraints: { id: %r{[^/]+} }
        resources :providers, only: %i[index show]
        resources :catalogues, only: %i[index show]
        resources :offers, only: %i[index show]
        resources :bundles, only: %i[index show]
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
  end

  # Sidekiq monitoring and split dashboard
  authenticate :user, lambda(&:admin?) do
    require "sidekiq/web"
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  resource :tour_histories, only: :create
  resource :tour_feedbacks, only: :create

  direct :overview_tour_first_service do |params|
    service = Service.where(status: %i[published unverified errored]).order(:name).first
    service_path(service, params)
  end


  resources :raid_projects do
    scope module: :raid_project do
      resources :steps, only: [:update, :show], controller: "steps"
    end
  end

  get "errors/not_found"
  get "errors/unprocessable"
  get "errors/internal_server_error"
  match "about", to: "pages#about", via: "get", as: :about
  match "target_users", to: "pages#target_users", via: "get", as: :target_users
  match "communities", to: "pages#communities", via: "get", as: :communities
  match "about_projects", to: "pages#about_projects", via: "get", as: :about_projects
  match "landing_page", to: "pages#landing_page", via: "get", as: :landing_page

  if Rails.env.development?
    get "designsystem" => "designsystem#index"
    get "designsystem/:file" => "designsystem#show", :constraints => { file: %r{[^/.]+} }
  end

  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  root "home#index"
end
