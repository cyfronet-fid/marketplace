# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def checkin
    auth = request.env["omniauth.auth"]

    if auth.uid.blank?
      flash[:alert] = "Cannot extract user uid from checkin response"
      redirect_to root_path
    else
      @user = User::Checkin.from_omniauth(auth)

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication, allow_other_host: true
        if cookies[:favourites].present?
          Array(cookies[:favourites].split("&")).each do |favourite|
            if UserService.find_by(user: @user, service: Service.find_by(slug: favourite)).blank?
              UserService.create(user: @user, service: Service.find_by(slug: favourite))
            end
          end
          cookies.delete(:favourites)
        end
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Checkin"
      else
        flash[:alert] = "Cannot register user #{@user.errors.inspect}"
        session["devise.checkin_data"] = auth
        redirect_to root_url
      end
    end
  end

  def after_omniauth_failure_path_for(_scope)
    root_path
  end
end
