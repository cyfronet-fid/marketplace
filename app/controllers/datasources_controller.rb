# frozen_string_literal: true

class DatasourcesController < ApplicationController
  def index
    search_service_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search
    redirect_to search_service_base_url + "/search/data_source?q=*" if enable_external_search
    @datasources = Datasource.visible.sort_by(&:name)
  end

  def show
    @datasource = Datasource.friendly.find(params[:id])
  end
end
