# frozen_string_literal: true

module Checkin
  class CheckVoMembership < ApplicationService
    CheckResult = Struct.new(:status, :access_token, :refresh_token, :become_vo_member_url, keyword_init: true)

    def initialize(access_token:, refresh_token:, config: Checkin::Config)
      super()

      @access_token = access_token
      @refresh_token = refresh_token
      @config = config
    end

    def call
      return result_for(:misconfiguration) if misconfigured?
      return result_for(:session_expired) if refresh_token.blank?

      # 1. Refresh token
      response = client.refresh_token(refresh_token)
      return result_for(:session_expired) unless response.success?

      update_credentials!(JSON.parse(response.body))

      # 2. Introspect token
      response = client.introspect(access_token)
      return result_for(:verification_failed) unless response.success?

      introspection = JSON.parse(response.body)
      return result_for(:session_expired) unless introspection["active"]

      result_for(status(introspection))
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, JSON::ParserError => e
      Rails.logger.tagged("CHECKIN").warn("Membership check failed: #{e.message}")

      result_for(:verification_failed)
    end

    private

    attr_reader :access_token, :refresh_token, :config

    def client
      @client ||= Checkin::Client.new
    end

    def update_credentials!(credentials)
      @access_token = credentials["access_token"].presence || access_token
      @refresh_token = credentials["refresh_token"].presence || refresh_token
    end

    def result_for(status)
      CheckResult.new(
        status: status,
        access_token: access_token,
        refresh_token: refresh_token,
        become_vo_member_url: become_vo_member_url
      )
    end

    def status(introspection)
      entitlements = introspection["entitlements"] || []
      group_tag = "group:#{vo_group_name}"

      entitlements.any? { _1.include?(group_tag) } ? :member : :not_member
    end

    def misconfigured?
      become_vo_member_url.blank? || vo_group_name.blank?
    end

    def become_vo_member_url
      config.become_vo_member_url
    end

    def vo_group_name
      config.vo_group_name
    end
  end
end
