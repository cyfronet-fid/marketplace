# frozen_string_literal: true

module OmniauthHelper
  def stub_omniauth(provider, options = {})
    first_name = options.fetch(:first_name, "John")
    last_name = options.fetch(:last_name, "Doe")
    email = options.fetch(:email, "#{first_name}.#{last_name}@email.pl")
    uid = options.fetch(:uid, 123)

    OmniAuth.config.add_mock(
      provider,
      info: {
        first_name: first_name,
        last_name: last_name,
        email: email
      },
      provider: provider,
      uid: uid
    )
  end

  def stub_checkin(user)
    stub_omniauth(:checkin, first_name: user.first_name, last_name: user.last_name, email: user.email, uid: user.uid)
  end

  def checkin_sign_in_as(user)
    stub_checkin(user)
    visit user_checkin_omniauth_authorize_path
  end
end
