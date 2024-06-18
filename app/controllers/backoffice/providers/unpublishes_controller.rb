# frozen_string_literal: true

class Backoffice::Providers::UnpublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    result = params[:suspend] ? Provider::Suspend.call(@provider) : Provider::Unpublish.call(@provider)
    if result
      flash[:notice] = "Provider #{params[:suspend] ? "suspended" : "unpublished"} successfully"
    else
      flash[:alert] = "Provider not #{params[:suspend] ? "suspended" : "unpublished"}. " +
        "Reason: #{@provider.errors.full_messages.join(", ")}"
    end
    redirect_to backoffice_provider_path(@provider)
  end

  private

  def find_and_authorize
    @provider = Provider.friendly.find(params[:provider_id])

    authorize(@provider, params[:suspend] ? :suspend? : :unpublish?)
  end
end
