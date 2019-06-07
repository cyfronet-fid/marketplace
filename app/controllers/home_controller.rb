# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_services

  def index
  end

  private

    def load_services
      @providers_number = Provider.count
      @services_number = Service.count
      @countries_number = 32
      @services = Service.includes(:providers).order(rating: :asc, title: :desc).limit(8)
    end
end
