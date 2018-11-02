# frozen_string_literal: true

class HomeController < ApplicationController
  include Service::Searchable

  before_action :load_categories_and_services

  def index
  end

  private

    def load_categories_and_services
      @categories = Category.limit(4)
      @sample_services = @categories.map do |category|
        Service.joins(:service_categories).where("service_categories.category_id": category.id).order(title: :desc).limit(8)
      end
      @other_services = Service.order(title: :desc).limit(8)
    end
end
