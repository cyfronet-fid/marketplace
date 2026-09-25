# frozen_string_literal: true

module Users
  class Authenticate < ApplicationService
    def initialize(auth)
      super()

      @auth = auth
    end

    def call
      identity_match || email_match || new_user_with_primary_identity
    end

    private

    attr_reader :auth

    def identity_match
      UserIdentity.find_by(provider: auth["provider"], uid: auth["uid"])&.user
    end

    def email_match
      email = auth.dig("info", "email")
      return if email.blank?

      user = User.where("lower(email) = lower(?)", email).first
      return unless user

      identity = user.identities.new(**new_identity_attributes, primary: false)
      return user if identity.save

      identity_match
    end

    def new_user_with_primary_identity
      user = User.new(new_user_attributes)
      user.identities.build(**new_identity_attributes, primary: true)
      user.save

      user
    end

    def new_user_attributes
      {
        email: auth.dig("info", "email"),
        password: SecureRandom.hex(32),
        first_name: auth.dig("info", "first_name"),
        last_name: auth.dig("info", "last_name")
      }
    end

    def new_identity_attributes
      { provider: auth["provider"], email_verified: auth.dig("info", "email_verified") || false, uid: auth["uid"] }
    end
  end
end
