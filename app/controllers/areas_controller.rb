# frozen_string_literal: true

class AreasController < ApplicationController
  include Service::Searchable
  include Paginable

  before_action :area

  def show
    @services = paginate(area_services)
  end

  private

    def area
      @area ||= Area.find(params[:id])
    end

    def area_services
      Service.joins(:service_areas).
              where(service_areas: { area_id: params[:id] })
    end
end
