# frozen_string_literal: true

require "uri"

module Checkin
  module Config
    module_function

    def client_options
      Devise.omniauth_configs[:checkin].strategy.client_options
    end

    def become_vo_member_url
      ENV.fetch("BECOME_VO_MEMBER_URL", "https://core-proxy.sandbox.eosc-beyond.eu/auth/realms/core/account/#/enroll?groupPath=/eosc-beyond.eu")
    end

    def vo_group_name
      ENV.fetch("VO_GROUP_NAME", "eosc-beyond.eu")
    end

    def introspection_url(options = client_options)
      options[:introspection_uri]
    end

    def token_url(options = client_options)
      URI::Generic.build(
        scheme: options[:scheme],
        host: options[:host],
        port: options[:port],
        path: options[:token_endpoint]
      ).to_s
    end
  end
end
