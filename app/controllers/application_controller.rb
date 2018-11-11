# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
  include Sentryable
  include Pundit

  before_action :load_root_categories!, :set_search_submit_path

  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_back fallback_location: root_path,
                  alert: "You are not authorized to see this page"
  end

  def set_search_submit_path
    @search_submit_path = services_path
  end

  private

    def load_root_categories!
      @root_categories = Category.roots.order(:name)
    end
end
