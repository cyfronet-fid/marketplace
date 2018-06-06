# frozen_string_literal: true

class CustomFailure < Devise::FailureApp
  def redirect_url
    user_checkin_omniauth_authorize_path
  end
end
