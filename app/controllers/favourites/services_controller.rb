# frozen_string_literal: true

class Favourites::ServicesController < FavouritesController
  def update
    @service = Service.where(slug: params.fetch(:favourite)).first
    if params.fetch(:update) == "true"
      UserService.new(user: current_user, service: @service).save
      respond_to do |format|
        format.js { render_modal_form }
      end
    else
      UserService.find_by(user: current_user, service: @service).destroy
    end
  end

  private
    def render_modal_form
      render "layouts/show_modal",
             content_type: "text/javascript",
             locals: {
               title: "Great!",
               action_btn: "OK",
               form: "layouts/popup",
               form_locals: {}
             }
    end
end
