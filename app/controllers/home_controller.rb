# frozen_string_literal: true

class HomeController < ApplicationController
  include Service::Searchable

  before_action :products

  def index
  end

  def products
    @categories = Category.limit(4)
  end
end
