# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable

  def index
    @services = records.page(params[:page])
    @subcategories = Category.roots
  end

  def show
    @service = Service.find(params[:id])
  end
end
