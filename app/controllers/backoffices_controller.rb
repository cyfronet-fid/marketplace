# frozen_string_literal: true

class BackofficesController < Backoffice::ApplicationController
  def show
    if current_user&.providers&.size&.positive? || policy_scope(Provider).size.positive?
      redirect_to backoffice_services_path
    else
      redirect_to backoffice_providers_path
    end
  end
end
