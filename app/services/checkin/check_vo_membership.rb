# frozen_string_literal: true

module Checkin
  class CheckVoMembership < ApplicationService
    Result = Struct.new(:status, :access_token, :refresh_token, keyword_init: true)

    def initialize(access_token:, refresh_token:)
      super()

      @access_token = access_token
      @refresh_token = refresh_token
    end

    def call
      if refresh_token.blank?
        Checkin::Logger.warn("Missing credentials")
        return session_expired_result
      end

      # 1. Refresh token
      response = client.refresh_token(refresh_token)
      return session_expired_result unless response.success?

      credentials = JSON.parse(response.body)
      @access_token = credentials["access_token"].presence || access_token
      @refresh_token = credentials["refresh_token"].presence || refresh_token

      # 2. Introspect token
      response = client.introspect(access_token)
      return verification_failed_result unless response.success?

      introspection = JSON.parse(response.body)
      return session_expired_result unless introspection["active"]

      Result.new(
        status: status(introspection),
        access_token: access_token,
        refresh_token: refresh_token
      )
    rescue Faraday::Error, JSON::ParserError => e
      Checkin::Logger.warn("Membership check failed: #{e.message}")

      verification_failed_result
    end

    private

    attr_reader :access_token, :refresh_token

    def client
      @client ||= Checkin::Client.new
    end

    def session_expired_result
      Result.new(status: :session_expired)
    end

    def verification_failed_result
      Result.new(
        status: :verification_failed,
        access_token: access_token,
        refresh_token: refresh_token
      )
    end

    def status(introspection)
      entitlements = introspection["entitlements"] || []
      group_entitlement = "group:#{Checkin::Config.vo_group_name}"

      entitlements.include?(group_entitlement) ? :member : :not_member
    end
  end
end
