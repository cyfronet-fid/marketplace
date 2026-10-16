# frozen_string_literal: true

module Service::Monitorable
  extend ActiveSupport::Concern

  # The monitoring endpoint answered without a status value.
  # MonitoringData::Request raises Errno::ECONNREFUSED for a blank response
  # and for a status outside 200 (lib/monitoring_data/fetch.rb rescues it).
  class EndpointError < StandardError
  end

  def fetch_status(service_pid)
    return "UNKNOWN" unless Mp::Application.config.monitoring_data_enabled

    response =
      MonitoringData::Request.call(
        Mp::Application.config.monitoring_data_host,
        "v3/status/Default",
        id: service_pid.to_s.partition(".").last,
        faraday: Faraday,
        access_token: Mp::Application.config.monitoring_data_token
      )
    body = response.body
    status = body.is_a?(Hash) ? body.dig("endpoints", 0, "statuses", 0, "value") : nil
    raise EndpointError, "monitoring endpoint answered without a status value" if status.nil?

    status
  rescue Faraday::Error, Errno::ECONNREFUSED, EndpointError => e
    raise if Rails.env.development?

    Sentry.capture_exception(
      e,
      extra: {
        url: "#{Mp::Application.config.monitoring_data_host}/v3/status/Default",
        response_status: response&.status,
        response_body: response&.body.to_s.truncate(500),
        service_pid: service_pid
      }
    )
    "MISSING"
  end
end
