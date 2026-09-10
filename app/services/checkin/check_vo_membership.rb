# frozen_string_literal: true

module Checkin
  class CheckVoMembership < ApplicationService
    Result = Struct.new(:status, :access_token, :refresh_token, :become_vo_member_url, keyword_init: true)

    def initialize(access_token:, refresh_token:)
      super()

      @access_token = access_token
      @refresh_token = refresh_token
    end

    def call
      return result_for(:session_expired) if refresh_token.blank?
      return result_for(:misconfiguration) if vo_group_name.blank? || become_vo_member_url.blank?

      # 1. Refresh token
      response = client.refresh_token(refresh_token)
      return result_for(:session_expired) unless response.success?

      credentials = JSON.parse(response.body)
      @access_token = credentials["access_token"].presence || access_token
      @refresh_token = credentials["refresh_token"].presence || refresh_token

      # 2. Introspect token
      response = client.introspect(access_token)
      return result_for(:verification_failed) unless response.success?

      introspection = JSON.parse(response.body)
      return result_for(:session_expired) unless introspection["active"]

      result_for(status(introspection))
    rescue Faraday::Error, JSON::ParserError => e
      Checkin::Logger.warn("Membership check failed: #{e.message}")

      result_for(:verification_failed)
    end

    private

    attr_reader :access_token, :refresh_token

    def client
      @client ||= Checkin::Client.new
    end

    def result_for(status)
      Result.new(
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

    def become_vo_member_url
      ENV.fetch("BECOME_VO_MEMBER_URL", nil)
    end

    def vo_group_name
      ENV.fetch("VO_GROUP_NAME", nil)
    end
  end
end
