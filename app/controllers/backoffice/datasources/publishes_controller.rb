# frozen_string_literal: true

class Backoffice::Datasources::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    Datasource::Publish.call(@datasource, verified: verified?)
    redirect_to [:backoffice, @datasource]
  end

  private

  def find_and_authorize
    @datasource = Datasource.friendly.find(params[:datasource_id])

    authorize(@datasource, verified? ? :publish? : :publish_unverified?)
  end

  def verified?
    params[:unverified] != "true"
  end
end
