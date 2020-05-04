# frozen_string_literal: true

require "google/api_client/auth/key_utils"

class Google::Analytics
  def initialize
    @client = auth
    @client.fetch_access_token!
    @analytics = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
    @analytics.authorization = @client
  rescue StandardError => e
    print e
  end

  def views(page_path, start_date = Date.new(2018, 11, 1), end_date = Date.today)
    date_range = Google::Apis::AnalyticsreportingV4::DateRange.new(start_date: start_date, end_date: end_date)
    dimension = Google::Apis::AnalyticsreportingV4::Dimension.new(name: "ga:pagePath")
    metrics = []
    metrics << Google::Apis::AnalyticsreportingV4::Metric.new(expression: "ga:pageviews")
    metrics << Google::Apis::AnalyticsreportingV4::Metric.new(expression: "ga:exits")

    request = Google::Apis::AnalyticsreportingV4::GetReportsRequest.new(report_requests: [
        Google::Apis::AnalyticsreportingV4::ReportRequest.new(view_id: view_id.to_s,
                                                              dimensions: [dimension],
                                                              metrics: metrics,
                                                              date_ranges: [date_range],
                                                              filters_expression: "ga:pagePath=~^#{page_path}($|[^/])"
        )]
    )

    response = @analytics.batch_get_reports(request)
    { views: response.reports.first.data.totals.first.values.first,
      redirects: response.reports.first.data.totals.first.values.second }
  rescue StandardError
    { views: "GA not initialized",
      redirects: "GA not initialized" }
  end

  private
    def auth
      Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: key,
                                                         scope: "https://www.googleapis.com/auth/analytics.readonly")
      rescue []
    end

    def key
      File.open(ENV["GOOGLE_AUTH_KEY_FILEPATH"] || "config/google_api_key.json") rescue nil
    end

    def view_id
      ENV["GOOGLE_VIEW_ID"] || Rails.application.credentials.google[:view_id]
    end
end
