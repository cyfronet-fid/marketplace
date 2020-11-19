# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
  include Sentryable
  include Pundit
  include Devise::StoreLocation

  before_action :welcome_popup, :load_root_categories!, :report

  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_back fallback_location: root_path,
                  alert: not_authorized_message(exception)
  end

  def tour_disabled
    false
  end

  private
    def welcome_popup
      @show_popup = current_user&.show_welcome_popup || false
      if @show_popup && !tour_disabled
        current_user.update(show_welcome_popup: false)
      end
    end

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
