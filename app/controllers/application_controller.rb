# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Sentryable
  include Pundit::Authorization
  include Devise::StoreLocation
  include FastGettext::Translation
  include Recommendation::Followable
  include Tourable

  before_action :welcome_popup, :load_root_categories!, :report, :set_locale, :set_gettext_locale

  protect_from_forgery

  rescue_from ActiveRecord::RecordNotFound do |_|
    redirect_back fallback_location: "/404"
  end

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_to root_path(anchor: ""), alert: not_authorized_message(exception)
  end

  def tour_disabled
    false
  end

  private

  def load_query_params_from_session
    @query_params = session[:query] || {}
  end

  def welcome_popup
    @show_welcome_modal = current_user&.show_welcome_popup || false
    current_user.update(show_welcome_popup: false) if @show_welcome_modal && !tour_disabled
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

  def set_locale
    FastGettext.available_locales = ["en"]
    FastGettext.text_domain = "marketplace"

    FastGettext.locale = "en"
    # #if you want automatic language detection:
    #   - replace line `FastGettext.locale = "en"` with below lines:
    #     FastGettext.set_locale(params[:locale] || session[:locale] || request.env['HTTP_ACCEPT_LANGUAGE'])
    #     session[:locale] = I18n.locale = FastGettext.locale
    #   - put specific language shortcut (for example "pl") to the `FastGettext.available_locales` array above
    #   - put specific language shortcut (for example "pl") to the `FastGettext.default_available_locales`
    #     in the file `config/initializers/fast_gettext.rb`
  end

  def choose_layout
    case params[:from]
    when "backoffice_service"
      "backoffice"
    when "ordering_configuration"
      "ordering_configuration"
    else
      "application"
    end
  end
end
