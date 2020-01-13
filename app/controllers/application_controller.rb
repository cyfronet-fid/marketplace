# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
  include Sentryable
  include Pundit
  include Devise::StoreLocation

  before_action :load_root_categories!, :report

  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_back fallback_location: root_path,
                  alert: not_authorized_message(exception)
  end

  private
    def report
      @report = Report.new
    end

    def load_root_categories!
      @root_categories = Category.roots.order(:name)
    end

    def not_authorized_message(exception)
      policy_name = exception.policy.class.to_s.underscore
      I18n.t "#{policy_name}.#{exception.query}", scope: :pundit, default: :default
    end
end
