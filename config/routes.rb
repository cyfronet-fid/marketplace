# frozen_string_literal: true

Rails.application.routes.draw do
  resources :services, only: [:index, :show]
  root "home#index"
end
