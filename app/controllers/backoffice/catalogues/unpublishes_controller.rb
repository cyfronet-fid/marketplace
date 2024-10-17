# frozen_string_literal: true

class Backoffice::Catalogues::UnpublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    result = params[:suspend] ? Catalogue::Suspend.call(@catalogue) : Catalogue::Unpublish.call(@catalogue)
    respond_to do |format|
      if result
        flash[:notice] = "Catalogue #{params[:suspend] ? "suspended" : "unpublished"} successfully"
      else
        flash[:alert] = "Catalogue not #{params[:suspend] ? "suspended" : "unpublished"}. " +
          "Reason: #{@catalogue.errors.full_messages.join(", ")}"
      end
      format.turbo_stream
      format.html { redirect_to backoffice_catalogue_path(@catalogue) }
    end
  end

  private

  def find_and_authorize
    @catalogue = Catalogue.friendly.find(params[:catalogue_id])

    authorize(@catalogue, params[:suspend] ? :suspend? : :unpublish?)
  end
end
