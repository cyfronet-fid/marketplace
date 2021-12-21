# frozen_string_literal: true

require "google/api_client/auth/key_utils"

class Analytics::PageViewsAndRedirects
  def initialize(analytics)
    analytics.login
    @analytics = analytics
  end

  def call(page_path, start_date = Date.new(2018, 11, 1), end_date = Date.today)
    date_range = Google::Apis::AnalyticsreportingV4::DateRange.new(start_date: start_date, end_date: end_date)
    dimension = Google::Apis::AnalyticsreportingV4::Dimension.new(name: "ga:pagePath")
    metrics = []
    metrics << Google::Apis::AnalyticsreportingV4::Metric.new(expression: "ga:pageviews")
    metrics << Google::Apis::AnalyticsreportingV4::Metric.new(expression: "ga:exits")

    request =
      Google::Apis::AnalyticsreportingV4::GetReportsRequest.new(
        report_requests: [
          Google::Apis::AnalyticsreportingV4::ReportRequest.new(
            view_id: @analytics.view_id.to_s,
            dimensions: [dimension],
            metrics: metrics,
            date_ranges: [date_range],
            filters_expression: "ga:pagePath=~^#{page_path}($|[^/])"
          )
        ]
      )

    response = @analytics.service.batch_get_reports(request)
    {
      views: response.reports.first.data.totals.first.values.first,
      redirects: response.reports.first.data.totals.first.values.second
    }
  rescue StandardError => e
    puts e
    { views: "GA not initialized", redirects: "GA not initialized" }
  end
end
