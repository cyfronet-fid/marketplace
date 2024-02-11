# frozen_string_literal: true

class CataloguesController < ApplicationController
  def index
    @catalogues = policy_scope(Catalogue).order(:name)
  end

  def show
    @catalogue = Catalogue.with_attached_logo.friendly.find(params[:id])
    authorize(@catalogue)
  end
end
