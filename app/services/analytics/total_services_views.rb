# frozen_string_literal: true

class Analytics::TotalServicesViews
  def initialize(analytics)
    analytics.login
    @analytics = analytics
  end

  def call(path, start_date = Date.new(2018, 11, 1), end_date = Date.today)
    date_range = Google::Apis::AnalyticsreportingV4::DateRange.new(start_date: start_date, end_date: end_date)
    dimension = Google::Apis::AnalyticsreportingV4::Dimension.new(name: "ga:pagePath")
    metrics = [Google::Apis::AnalyticsreportingV4::Metric.new(expression: "ga:pageviews")]
    request =
      Google::Apis::AnalyticsreportingV4::GetReportsRequest.new(
        report_requests: [
          Google::Apis::AnalyticsreportingV4::ReportRequest.new(
            view_id: @analytics.view_id.to_s,
            dimensions: [dimension],
            metrics: metrics,
            date_ranges: [date_range],
            filters_expression: "ga:pagePath=~^/#{path}/[^(c/)]"
          )
        ]
      )
    response = @analytics.service.batch_get_reports(request)
    response.reports.first.data
  rescue StandardError => e
    print e
  end
end
