# frozen_string_literal: true

class CataloguesController < ApplicationController
  def show
    @catalogue = Catalogue.friendly.find(params[:id])
  end
end
