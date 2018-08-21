# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable

  def index
    @services = records.page(params[:page])
    @subcategories = Category.roots
  end

  def show
    @service = Service.find(params[:id])
    @service_opinions = ServiceOpinion.joins(:order).where(orders: { service: @service })
    @service_opinions_size = @service_opinions.size
  end
end
