# frozen_string_literal: true

module Devise::StoreLocation
  extend ActiveSupport::Concern

  included do
    prepend_before_action :store_user_location!, if: :storable_location?
  end

  private

    def storable_location?
      request.get? && is_navigational_format? &&
        !devise_controller? && !request.xhr?
    end

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end
end
