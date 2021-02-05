# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    @providers = Provider.all.order(:name)
  end

  def show
    @provider = Provider.find(params[:id])
  end
end
