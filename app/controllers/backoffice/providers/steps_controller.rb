# frozen_string_literal: true

class Backoffice::Providers::StepsController < Backoffice::ProvidersController
  include Backoffice::ProvidersHelper
  include UrlHelper
  skip_before_action :backoffice_authorization!
  before_action :validate_wizard_action, only: :show
  before_action :current_step, only: :show
  before_action :find_and_authorize

  helper_method :prev_step

  class WizardActionError < StandardError
  end

  class CommitValueError < StandardError
  end

  FORM_STEPS = {
    profile: %i[name abbreviation description website logo legal_entity],
    location: %i[street_name_and_number postal_code city region country],
    contacts: [
      main_contact_attributes: %i[id first_name last_name email country_phone_code phone position],
      public_contacts_attributes: %i[id first_name last_name email country_phone_code phone position _destroy]
    ],
    managers: [data_administrators_attributes: %i[id first_name last_name email _destroy]]
  }.freeze

  def show
    @provider.current_step = session[:provider_step]
    prepare_step(@provider.current_step.to_sym)
  end

  def update
    saved_params = session[session_key]
    provider_attrs = saved_params.merge permitted_step_attributes
    @provider.assign_attributes provider_attrs.except("logo")
    provider_attrs["logo"] = logo(provider_attrs) if provider_attrs["logo"].present? && current_step_index.zero?
    if @provider.valid?
      session[session_key] = provider_attrs
      redirect_to_next_step(params[:commit])
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def target_step(commit)
    raise CommitValueError, "Unknown commit value" if commit.blank?
    @provider.current_step = session[:provider_step]

    case commit
    when next_title
      @provider.next_step
    when back_title
      @provider.previous_step
    else
      target_step_value = commit.split.last&.downcase
      @provider.go_to_step(target_step_value)
    end
  end

  def redirect_to_next_step(commit)
    if @provider.current_step == "summary"
      finish_wizard_path
    else
      @provider.current_step = step = target_step(commit)
      session[:provider_step] = step
      prepare_step(step.to_sym)
      render turbo_stream:
               turbo_stream.update(
                 "provider-form",
                 partial: partial_path(step),
                 locals: {
                   provider: @provider,
                   logo: @logo
                 }
               )
    end
  end

  def finish_wizard_path
    saved_params = session[session_key]
    @logo = saved_params.delete("logo")
    if session_key == "new"
      @provider.status = :unpublished
      if @provider.save
        if current_user.providers.published.empty? && !current_user.coordinator?
          ar = ApprovalRequest.new(approvable: @provider, user: current_user, status: :published)
          ar.save
        end
      else
        render :show, status: :unprocessable_entity
      end
    else
      init_provider(session_key, saved_params.except("logo"))
      render :show, status: :unprocessable_entity unless @provider.update(saved_params)
    end
    @provider.update_logo!(@logo) if @logo.present?
    action = session.delete(:wizard_action)
    clear_session_data
    redirect_to backoffice_providers_path(format: :html), notice: "Provider #{action}d successfully"
  end

  def prepare_step(step_to_set)
    find_and_authorize
    case step_to_set
    when :contacts
      @provider.build_main_contact if @provider.main_contact.blank?
      @provider.public_contacts.build if @provider.public_contacts.empty?
    when :managers
      if @provider.data_administrators.blank?
        @provider.data_administrators << DataAdministrator.new(
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          email: current_user.email
        )
      end
    when :summary
      @logo = session[session_key]["logo"]
    end
  end

  def current_step_index
    basic_steps.index(@provider.current_step)
  end

  def prev_step
    @provider.previous_step
  end

  def current_step
    session[:provider_step] = params[:step] if params[:step]
    session[:provider_step]
  end

  def total_steps
    basic_steps.size
  end

  def permitted_step_attributes
    if current_step_index + 1 < total_steps
      params.require(:provider).permit(:current_step, *FORM_STEPS[@provider.current_step.to_sym])
    else
      {}
    end
  end

  def validate_wizard_action
    if session[:wizard_action].nil? || !%w[create update].include?(session[:wizard_action])
      raise WizardActionError, "wizard_action parameter not set"
    end
  end

  def find_and_authorize
    session[session_key] ||= {}
    provider_attrs = session[session_key]
    @provider = init_provider(session_key, provider_attrs.except("logo"))
  end

  def init_provider(provider_id, provider_attrs)
    if provider_id == "new"
      p = Provider.new(provider_attrs)
    else
      p = Provider.with_attached_logo.friendly.find(provider_id)
      p.assign_attributes(provider_attrs.except("logo"))
    end
    p.current_step = session[:provider_step]
    p
  end

  def logo(provider_attrs)
    @logo ||=
      if provider_attrs["logo"].present?
        provider_attrs["logo"].is_a?(Hash) ? provider_attrs["logo"] : ImageHelper.to_json(provider_attrs["logo"])
      end
  end

  def session_key
    params[:provider_id]
  end
end
