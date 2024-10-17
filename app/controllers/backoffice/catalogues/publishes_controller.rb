# frozen_string_literal: true

class Backoffice::Catalogues::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    respond_to do |format|
      if Catalogue::Publish.call(@catalogue)
        flash[:notice] = _("Catalogue published successfully")
      else
        flash[:alert] = "Catalogue not published. Reason: #{@catalogue.errors.full_messages.join(", ")}"
      end
      format.turbo_stream
      format.html { redirect_to backoffice_catalogue_path(@catalogue) }
    end
  end

  private

  def find_and_authorize
    @catalogue = Catalogue.friendly.find(params[:catalogue_id])
    authorize(@catalogue, :publish?)
  end
end
