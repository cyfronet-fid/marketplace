# frozen_string_literal: true

module Service::Monitorable
  extend ActiveSupport::Concern
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
    response.body["endpoints"].first["statuses"].first["value"]
  rescue StandardError
    Sentry.capture_message("Monitoring service, monitoring endpoint response error")
    "MISSING"
  end
end
