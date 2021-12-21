# frozen_string_literal: true

class User::Checkin
  def self.from_omniauth(auth)
    User
      .default_scoped
      .find_or_create_by(uid: auth.uid) do |user|
        user.first_name = auth.info.first_name
        user.last_name = auth.info.last_name
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
      end
  end
end
