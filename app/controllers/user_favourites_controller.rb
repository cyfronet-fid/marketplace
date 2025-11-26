# frozen_string_literal: true

class UserFavouritesController < ApplicationController
  before_action :authenticate_user!

  def destroy
    favourite = current_user.user_favourites.find(params[:id])
    favourite.destroy
    respond_to do |format|
      format.html { redirect_to favourites_path, notice: "Removed from favourites" }
      format.turbo_stream { redirect_to favourites_path }
      format.json { head :no_content }
    end
  end
end
