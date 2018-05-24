# frozen_string_literal: true

class ServicesController < ApplicationController
  def index
    @services = records.page(params[:page])
  end

  def show
    @service = Service.find(params[:id])
  end

  private

    def records
      params[:q].blank? ? Service.all : Service.where(id: search_ids)
    end

    def search_ids
      Service.search(params[:q]).records.ids
    end
end
