# frozen_string_literal: true

# HTTP client of the Application Deployment Manager (ADM) API.
# Request paths are relative, so the /adim/ prefix of the base URL is kept.
class Adm::Client
  def self.config
    Rails.application.config.deployable_services.with_indifferent_access
  end

  def initialize(access_token: nil, config: self.class.config[:application_deployment_manager])
    @access_token = access_token
    @config = config
  end

  def base_url
    @config[:base_url]
  end

  def create_allocation(host:, domain:)
    response =
      request(
        :post,
        "allocations",
        kind: "EGIComputeEnvironment",
        authVersion: "3.x-oidc",
        userName: "egi.eu",
        tenant: "openid",
        domain: domain,
        host: host
      )

    allocation_id(response) || raise(Adm::Error, "ADM returned no allocation id")
  end

  def create_deployment(allocation_id:, application_id:, inputs:)
    response =
      request(
        :post,
        "deployments",
        allocation: {
          kind: "AllocationId",
          id: allocation_id,
          infoLink: url_for("allocation", allocation_id)
        },
        application: {
          kind: "ApplicationId",
          id: application_id,
          infoLink: url_for("application", application_id)
        },
        inputs: inputs.map { |name, value| { name: name, value: value } }
      )

    response.body.fetch("id")
  end

  def deployment(id)
    body = request(:get, path("deployment", id)).body

    Adm::Deployment.new(
      id: body["id"],
      status: body["status"],
      details: body["details"],
      outputs: Array(body["outputs"]).to_h { |output| [output["name"], output["value"]] }
    )
  end

  def delete_deployment(id)
    request(:delete, path("deployment", id))
    true
  end

  private

  def request(method, path, body = nil)
    connection.public_send(method, path, body)
  rescue Faraday::ResourceNotFound => e
    raise Adm::NotFound, error_message(e)
  rescue Faraday::Error => e
    raise Adm::Error, error_message(e)
  end

  def connection
    @connection ||=
      Faraday.new(base_url) do |conn|
        conn.request :json
        conn.response :raise_error
        conn.response :json
        conn.headers["Authorization"] = "Bearer #{access_token}"
        conn.options.timeout = @config[:timeout]
        conn.options.open_timeout = @config[:open_timeout]
      end
  end

  def access_token
    @access_token ||= Checkin::ServiceAccountToken.call
  end

  def allocation_id(response)
    return response.body["id"] if response.body.is_a?(Hash) && response.body["id"].present?

    response.headers["Location"].to_s.split("/").last.presence
  end

  def path(*segments)
    segments.map { |segment| ERB::Util.url_encode(segment) }.join("/")
  end

  def url_for(*segments)
    URI.join(base_url, path(*segments)).to_s
  end

  def error_message(error)
    status = error.response&.dig(:status)
    body = error.response&.dig(:body)
    description = body.is_a?(Hash) ? body["description"] || body["detail"] : body.presence
    ["ADM request failed", status, description || "#{error.class}: #{error.message}"].compact.join(": ")
  end
end
