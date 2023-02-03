# frozen_string_literal: true

class DatasourcesController < ApplicationController
  def index
    search_base_url = Mp::Application.config.search_base_url
    if search_base_url
      redirect_to search_base_url + "/search/data-source?q=*"
    end
    @datasources = Datasource.visible.sort_by(&:name)
  end

  def show
    @datasource = Datasource.friendly.find(params[:id])
  end
end
