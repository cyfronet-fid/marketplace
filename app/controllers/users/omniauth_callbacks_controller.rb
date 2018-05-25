# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def checkin
    auth = request.env["omniauth.auth"]
    # puts "auth #{auth.inspect}"

    if auth.uid.blank?
      flash[:alert] = "Cannot extract user uid from checkin response"
      redirect_to root_path
    else
      @user = User::Checkin.from_omniauth(auth)

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: "Checkin") if is_navigational_format?
      else
        flash[:alert] = "Cannot register user #{@user.errors.inspect}"
        session["devise.checkin_data"] = auth
        redirect_to root_url
      end
    end
  end
end
