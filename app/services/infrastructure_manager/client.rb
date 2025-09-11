# frozen_string_literal: true

class InfrastructureManager::Client < ApplicationService
  BASE_URL = "https://deploy.sandbox.eosc-beyond.eu"

  def initialize(access_token = nil)
    super()
    @access_token = access_token
    @connection = build_connection
  end

  def create_infrastructure(tosca_template)
    response =
      @connection.post("/infrastructures") do |req|
        req.headers.merge!(headers)
        req.body = tosca_template
      end

    handle_response(response)
  rescue Faraday::Error => e
    { success: false, error: "HTTP request failed: #{e.message}", status_code: nil }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}", status_code: nil }
  end

  def get_infrastructure_info(infrastructure_id)
    response = @connection.get("/infrastructures/#{infrastructure_id}") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    { success: false, error: "HTTP request failed: #{e.message}", status_code: nil }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}", status_code: nil }
  end

  def get_infrastructure_state(infrastructure_id)
    response = @connection.get("/infrastructures/#{infrastructure_id}/state") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    { success: false, error: "HTTP request failed: #{e.message}", status_code: nil }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}", status_code: nil }
  end

  def delete_infrastructure(infrastructure_id)
    response = @connection.delete("/infrastructures/#{infrastructure_id}") { |req| req.headers.merge!(headers) }

    handle_response(response)
  rescue Faraday::Error => e
    { success: false, error: "HTTP request failed: #{e.message}", status_code: nil }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}", status_code: nil }
  end

  private

  def build_connection
    Faraday.new(BASE_URL) do |conn|
      conn.request :json
      conn.response :json
      conn.adapter Faraday.default_adapter
      conn.options.timeout = 60
      conn.options.open_timeout = 30
    end
  end

  def headers
    { "Content-Type" => "text/yaml", "Accept" => "application/json", "Authorization" => authorization_header }
  end

  def authorization_header
    # Use Bearer token format as this gets better response from IM API
    "Bearer #{@access_token || demo_token}"
  end

  def demo_token
    # In a real implementation, this would come from the user's EGI token
    # For demo purposes, we'll use a placeholder
    ENV.fetch("IM_DEMO_TOKEN", "demo_token_placeholder")
  end

  def handle_response(response)
    case response.status
    when 200..299
      # Successful response
      { success: true, data: parse_response_body(response), status_code: response.status, headers: response.headers }
    when 400..499
      # Client error
      { success: false, error: "Client error: #{response.status} - #{response.body}", status_code: response.status }
    when 500..599
      # Server error
      { success: false, error: "Server error: #{response.status} - #{response.body}", status_code: response.status }
    else
      # Unexpected response
      {
        success: false,
        error: "Unexpected response: #{response.status} - #{response.body}",
        status_code: response.status
      }
    end
  end

  def parse_response_body(response)
    content_type = response.headers["content-type"]

    if content_type&.include?("application/json")
      # Faraday with json middleware might already parse JSON
      response.body.is_a?(String) ? JSON.parse(response.body) : response.body
    elsif content_type&.include?("text/yaml") || content_type&.include?("application/yaml")
      YAML.safe_load(response.body)
    else
      response.body
    end
  rescue JSON::ParserError, Psych::SyntaxError => e
    Rails.logger.warn "Failed to parse IM response body: #{e.message}"
    response.body
  end
end
