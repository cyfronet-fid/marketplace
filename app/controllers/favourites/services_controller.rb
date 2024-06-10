# frozen_string_literal: true

class Favourites::ServicesController < FavouritesController
  skip_before_action :authenticate_user!, only: :update

  def update
    @service = Service.where(slug: params.fetch(:favourite)).first
    cookies[:favourites] ||= []
    added = Array(cookies[:favourites].split("&"))
    p "OLE #{params.fetch(:update)} #{params.fetch(:update).class}"
    if params.fetch(:update)
      current_user.present? ? UserService.new(user: current_user, service: @service).save : added << @service.slug
      unless many?
        render turbo_stream:
                 turbo_stream.replace(
                   "popup-modal",
                   partial: "layouts/popup",
                   locals: {
                     popup_title: title,
                     popup_text: text,
                     logged: logged?
                   }
                 )
      end
    elsif current_user.present?
      UserService.find_by(user: current_user, service: @service)&.destroy
    else
      added.delete(@service.slug)
    end
    if current_user&.favourite_services&.empty?
      render turbo_stream: turbo_stream.replace("service-box", partial: "favourites/empty_box", type: "empty_box")
    end
    cookies[:favourites] = added.reject(&:blank?)
  end

  private

  def many?
    (UserService.where(user: current_user).size > 1) || ((cookies[:favourites]&.size || 0) > 1)
  end

  def text
    if logged?
      "You have added the first EOSC Service to your favourites list. \n" \
        "You can reach your Favourite Services using My EOSC Marketplace menu available in the top right corner."
    else
      "If you want this EOSC service to be added to your Favourite Services list, " \
        "please log in. In other case, we won't be able to remember this service as your favourite."
    end
  end

  def title
    logged? ? "Great!" : "Save your favourites!"
  end

  def logged?
    current_user.present?
  end
end
