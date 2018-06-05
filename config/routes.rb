# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  resources :services, only: [:index, :show]

  resource :profile, only: [:show]

  root "home#index"
end
