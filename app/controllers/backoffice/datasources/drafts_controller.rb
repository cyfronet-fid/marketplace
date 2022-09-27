# frozen_string_literal: true

class Backoffice::Datasources::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    Datasource::Draft.call(@datasource)
    redirect_to [:backoffice, @datasource]
  end

  private

  def find_and_authorize
    @datasource = Datasource.friendly.find(params[:datasource_id])

    authorize(@datasource, :draft?)
  end
end
