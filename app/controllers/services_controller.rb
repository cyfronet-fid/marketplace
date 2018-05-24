# frozen_string_literal: true

class ServicesController < ApplicationController
  def index
    @services = Service.paginate(page: params[:page])
  end

  def show
    @service = Service.find(params[:id])
  end
end
