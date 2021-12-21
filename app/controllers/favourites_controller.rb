# frozen_string_literal: true

class FavouritesController < ApplicationController
  include Service::Comparison
  before_action :authenticate_user!

  def index
    @favourites = current_user.favourite_services
  end

  private

  def render_popup_json(title, text, logged)
    render json: { html: popup(title, text, logged), type: "modal" }
  end

  def render_empty_box
    render json: { html: render_to_string(partial: "favourites/empty_box"), type: "empty_box" }
  end

  def popup(title, text, logged)
    render_to_string(
      partial: "layouts/popup",
      locals: {
        popup_title: title,
        popup_text: text,
        logged: logged
      },
      formats: [:html]
    )
  end
end
