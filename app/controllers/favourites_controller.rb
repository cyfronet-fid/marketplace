# frozen_string_literal: true

class FavouritesController < ApplicationController
  before_action :authenticate_user!

  def index
    @favourites = current_user.favourite_services
  end
end
