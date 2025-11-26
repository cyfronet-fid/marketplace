# frozen_string_literal: true

class FavouritesController < ApplicationController
  include Service::Comparison
  layout "clear", only: :index
  before_action :authenticate_user!

  def index
    # Load all favourites with preloaded favoritable objects
    @favourites = current_user.user_favourites.includes(:favoritable).to_a

    if params[:q].present?
      q = params[:q].to_s.downcase.strip
      @favourites =
        @favourites.select do |fav|
          obj = fav.favoritable
          name =
            case obj
            when Service, Offer
              obj.name
            when ResearchProduct
              obj.title
            else
              obj.respond_to?(:name) ? obj.name : obj.try(:to_s)
            end
          name.to_s.downcase.include?(q)
        end
    end

    # Sorting
    @sort = %w[name type order_type created_at].include?(params[:sort]) ? params[:sort] : "created_at"
    @dir = %w[asc desc].include?(params[:dir]) ? params[:dir] : "asc"

    @favourites.sort_by! do |fav|
      obj = fav.favoritable
      name =
        if obj.respond_to?(:name)
          obj.name
        elsif obj.respond_to?(:title)
          obj.title
        else
          obj.to_s
        end
      type_name = obj.class.name
      order_type = obj.respond_to?(:order_type) && obj.order_type.present? ? obj.order_type.to_s : "-"

      case @sort
      when "type"
        type_name.to_s
      when "order_type"
        order_type.to_s
      else
        name.to_s.downcase
      end
    end

    @favourites.reverse! if @dir == "desc"
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
