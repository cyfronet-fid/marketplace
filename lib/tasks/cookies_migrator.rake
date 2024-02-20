# frozen_string_literal: true

desc "Migrate cookies encryption to rails version"
namespace :encrypt_cookies do
  desc "Migrate to 7.0"
  task up: :environment do
    encrypt_cookies_with
  end

  desc "Migrate to 6.1"
  task down: :environment do
    encrypt_cookies_with(OpenSSL::Digest::SHA1)
  end

  def encrypt_cookies_with(algorithm = OpenSSL::Digest::SHA256)
    Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
      salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
      secret_key_base = Rails.application.secrets.secret_key_base

      key_generator = ActiveSupport::KeyGenerator.new(secret_key_base, iterations: 1000, hash_digest_class: algorithm)
      key_len = ActiveSupport::MessageEncryptor.key_len
      secret = key_generator.generate_key(salt, key_len)

      cookies.rotate :encrypted, secret
      cookies.rotate :signed, secret
    end
  end
end
