# frozen_string_literal: true

require "uri"

class Users::CheckinConfig
  def self.client_options
    Devise.omniauth_configs[:checkin].strategy.client_options
  end

  def self.become_vo_member_url
    Devise.omniauth_configs[:checkin].options[:become_vo_member_url]
  end

  def self.vo_group_name
    Rails.application.config.vo_group_name
  end

  def self.introspection_url(options = client_options)
    options[:introspection_uri]
  end

  def self.token_url(options = client_options)
    URI::Generic.build(
      scheme: options[:scheme],
      host: options[:host],
      port: options[:port],
      path: options[:token_endpoint]
    ).to_s
  end
end
