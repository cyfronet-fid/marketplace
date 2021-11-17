# frozen_string_literal: true

module Config
  class StompConnection
    attr_reader :login,
                string,
                presence: true,
                default: ENV["MP_STOMP_LOGIN"] || Rails.application.credentials.stomp.dig(:login) || "''"
    attr_reader :password,
                string,
                presence: true,
                default: ENV["MP_STOMP_PASS"] || Rails.application.credentials.stomp.dig(:password) || "''"
    attr_reader :host,
                string,
                presence: true,
                default: ENV["MP_STOMP_HOST"] || Rails.application.credentials.stomp.dig(:host) || "''"
    attr_reader :name,
                string,
                presence: true,
                default: ENV["MP_STOMP_CLIENT_NAME"] || "'MPClient'"
    attr_reader :ssl_enabled,
                  boolean,
                  presence: true,
                  default: ENV["MP_STOMP_SSL"] || false

    def to_hash
      {
        hosts: [
          {
            login: login,
            passcode: pass,
            host:  "#{host}",
            port: 61613,
            ssl: ssl
          }
        ],
        connect_headers: {
          "client-id": name,
          "heart-beat": "0,20000",
          "accept-version": "1.2",
          "host": "localhost"
        }
      }
    end
  end
end
