# frozen_string_literal: true

require "google/api_client/auth/key_utils"

class Google::Analytics
  attr_accessor :service, :credentials
  attr_reader :view_id

  def initialize
    @credentials = auth
    @service = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
    @view_id = google_view_id
    login
  rescue StandardError => e
    print e
  end

  def login
    @credentials.fetch_access_token!
    @service.authorization = @credentials
  rescue StandardError => e
    print e
    Rails.logger.warn("[WARN] Cannot connect to GA API")
  end

  private
    def auth
      Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: key,
                                                         scope: "https://www.googleapis.com/auth/analytics.readonly")
    rescue StandardError => e
      Rails.logger.warn("[WARN] Cannot make credentials for GA: #{e}")
    end

    def key
      path = ENV["GOOGLE_AUTH_KEY_FILEPATH"] || "config/google_api_key.json"
      File.open(path)
    rescue StandardError => e
      Rails.logger.warn("[WARN] Cannot load valid GA API key at path: #{path}: #{e}")
    end

    def google_view_id
      ENV["GOOGLE_VIEW_ID"] || Rails.application.credentials.google[:view_id]
    end
end
