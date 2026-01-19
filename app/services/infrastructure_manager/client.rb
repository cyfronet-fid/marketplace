# frozen_string_literal: true

class InfrastructureManager::Client < ApplicationService
  def initialize(access_token = nil, site = nil)
    super()
    @access_token = access_token
    @site = site || config.dig(:cloud_providers, :default)
    @connection = build_connection
  end

  class << self
    def config
      Rails.application.config.deployable_services.with_indifferent_access
    end
  end

  delegate :config, to: :class

  def create_infrastructure(tosca_template)
    response =
      @connection.post("/infrastructures") do |req|
        req.headers.merge!(headers)
        req.body = tosca_template
      end

    handle_response(response)
  rescue Faraday::Error => e
    error_msg = "HTTP request failed: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  rescue StandardError => e
    error_msg = "Unexpected error: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  end

  def get_outputs(infrastructure_id)
    response = @connection.get("/infrastructures/#{infrastructure_id}/outputs") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    error_msg = "HTTP request failed: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  rescue StandardError => e
    error_msg = "Unexpected error: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  end

  def get_vm_info(infrastructure_id, vm_id)
    response =
      @connection.get("/infrastructures/#{infrastructure_id}/vms/#{vm_id}") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    error_msg = "HTTP request failed: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  rescue StandardError => e
    error_msg = "Unexpected error: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  end

  def get_state(infrastructure_id)
    response = @connection.get("/infrastructures/#{infrastructure_id}/state") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    error_msg = "HTTP request failed: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  rescue StandardError => e
    error_msg = "Unexpected error: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  end

  def destroy_infrastructure(infrastructure_id)
    response = @connection.delete("/infrastructures/#{infrastructure_id}") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    error_msg = "HTTP request failed: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  rescue StandardError => e
    error_msg = "Unexpected error: #{e.class}: #{e.message}"
    Rails.logger.error error_msg
    { success: false, error: error_msg, status_code: nil }
  end

  private

  def build_connection
    im_config = config[:infrastructure_manager]
    Faraday.new(im_config[:base_url]) do |conn|
      conn.request :json
      conn.response :json
      conn.adapter Faraday.default_adapter
      conn.options.timeout = im_config[:timeout]
      conn.options.open_timeout = im_config[:open_timeout]
    end
  end

  def headers
    { "Content-Type" => "text/yaml", "Accept" => "application/json", "Authorization" => authorization_header }
  end

  def authorization_header
    token = @access_token || fresh_access_token
    vo = config.dig(:authentication, :vo)

    auth_lines = [
      "id = im; type = InfrastructureManager; token = #{token}",
      "id = egi; type = EGI; vo = #{vo}; token = #{token}#{"; host = #{@site}" if @site}"
    ]

    auth_lines.join("\\n")
  end

  def fresh_access_token
    auth_config = config[:authentication]
    cache_key = auth_config[:token_cache_key]
    cache_expiry = auth_config[:token_cache_expiry_minutes].minutes

    cached_token = Rails.cache.read(cache_key)
    return cached_token if cached_token

    env_token = ENV.fetch("EGI_ACCESS_TOKEN", nil)
    return env_token if env_token.present?

    refresh_token = ENV.fetch("EGI_REFRESH_ACCESS_TOKEN", nil)
    if refresh_token.present?
      new_token = refresh_egi_access_token(refresh_token)
      if new_token
        Rails.cache.write(cache_key, new_token, expires_in: cache_expiry)
        return new_token
      end
    end

    raise StandardError,
          "No EGI access token available. Set EGI_ACCESS_TOKEN or EGI_REFRESH_ACCESS_TOKEN environment variable."
  end

  def refresh_egi_access_token(refresh_token)
    auth_config = config[:authentication]
    response =
      Faraday.post(auth_config[:refresh_token_url]) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body =
          {
            grant_type: "refresh_token",
            refresh_token: refresh_token,
            client_id: auth_config[:client_id],
            scope: "openid email profile voperson_id eduperson_entitlement"
          }.map { |k, v| "#{k}=#{v}" }.join("&")
      end

    if response.success?
      token_data = JSON.parse(response.body)
      token_data["access_token"]
    else
      Rails.logger.error "Failed to refresh EGI access token: #{response.status} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error refreshing EGI access token: #{e.class}: #{e.message}"
    nil
  end

  def handle_response(response)
    parsed_body = parse_response_body(response)
    parsed_body = convert_to_indifferent_access(parsed_body)

    case response.status
    when 200..299
      { success: true, data: parsed_body, status_code: response.status, headers: response.headers }
    when 400..499
      error_msg = "Client error: #{response.status} - #{response.body}"
      Rails.logger.error error_msg
      { success: false, error: error_msg, status_code: response.status, data: parsed_body }
    when 500..599
      error_msg = "Server error: #{response.status} - #{response.body}"
      Rails.logger.error error_msg
      { success: false, error: error_msg, status_code: response.status, data: parsed_body }
    else
      error_msg = "Unexpected response: #{response.status} - #{response.body}"
      Rails.logger.error error_msg
      { success: false, error: error_msg, status_code: response.status, data: parsed_body }
    end
  end

  def parse_response_body(response)
    content_type = response.headers["content-type"]

    if content_type&.include?("application/json")
      response.body.is_a?(String) ? JSON.parse(response.body) : response.body
    elsif content_type&.include?("text/yaml") || content_type&.include?("application/yaml")
      YAML.safe_load(response.body)
    else
      response.body
    end
  rescue JSON::ParserError, Psych::SyntaxError
    response.body
  end

  def convert_to_indifferent_access(obj)
    case obj
    when Hash
      obj.with_indifferent_access.transform_values { |v| convert_to_indifferent_access(v) }
    when Array
      obj.map { |item| convert_to_indifferent_access(item) }
    else
      obj
    end
  end
end
