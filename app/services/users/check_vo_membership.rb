# frozen_string_literal: true

class Users::CheckVoMembership < ApplicationService
  Result = Struct.new(:status, :access_token, :refresh_token, :become_vo_member_url, keyword_init: true)

  def initialize(
    token:,
    refresh_token:,
    checkin_config: Users::CheckinConfig,
    introspect_service: Users::IntrospectAccessToken,
    refresh_service: Users::RefreshAccessToken
  )
    super()
    @token = token
    @refresh_token = refresh_token
    @checkin_config = checkin_config
    @introspect_service = introspect_service
    @refresh_service = refresh_service
  end

  def call
    if @token.blank?
      Rails.logger.warn("Missing check-in token in session")
      return Result.new(status: :session_expired)
    end

    introspection = @introspect_service.call(@token)
    return Result.new(status: :verification_failed) unless introspection.success

    new_access_token = nil
    new_refresh_token = nil

    unless introspection.active
      refresh = @refresh_service.call(@refresh_token)
      return Result.new(status: :session_expired) unless refresh.success

      new_access_token = refresh.access_token
      new_refresh_token = refresh.refresh_token

      introspection = @introspect_service.call(new_access_token)
      return Result.new(status: :verification_failed) unless introspection.success
    end

    has_membership = introspection.entitlements.any? { |e| e.include?("group:#{@checkin_config.vo_group_name}") }
    if has_membership
      return Result.new(status: :member, access_token: new_access_token,
                        refresh_token: new_refresh_token)
    end

    if @checkin_config.become_vo_member_url.blank?
      Rails.logger.error("Missing become_vo_member_url")
      return Result.new(status: :vo_url_missing)
    end

    Result.new(
      status: :not_member,
      access_token: new_access_token,
      refresh_token: new_refresh_token,
      become_vo_member_url: @checkin_config.become_vo_member_url
    )
  end
end
