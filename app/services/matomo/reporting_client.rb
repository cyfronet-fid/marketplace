# frozen_string_literal: true

module Matomo
  # Reads reports of this Node's Matomo site through the reporting API
  # (ADR-0008 D8), with the view-only MP_MATOMO_TOKEN_AUTH.
  class ReportingClient
    # A failed request: an HTTP error, a timeout, or an error result of Matomo.
    class Error < StandardError
    end

    # The Views of one event name on one day. The name is what
    # Matomo::Event.view gives the event: a PID, or "<service PID>:<iid>".
    ViewCount = Data.define(:name, :date, :views, :visits)

    OPEN_TIMEOUT = 10
    # Matomo may archive the requested days before it answers.
    READ_TIMEOUT = 120

    VIEW_LABEL_SUFFIX = " - View"
    private_constant :VIEW_LABEL_SUFFIX

    def initialize(configuration = Mp::Application.config.matomo)
      @configuration = configuration
    end

    # The View events of every day in dates (a Range of Date).
    #
    # Events.getName flattened into "<event name> - <event action>" rows is
    # the only report that has both the name and the action of an event. A
    # segment such as eventAction==View would not narrow it down: Matomo
    # segments select whole visits, so the other events of those visits
    # would still count.
    def views(dates)
      report = request(
        method: "Events.getName",
        period: "day",
        date: "#{dates.first.iso8601},#{dates.last.iso8601}",
        flat: 1,
        filter_limit: -1
      )

      report.flat_map do |date, rows|
        rows.filter_map { |row| view_count(Date.iso8601(date), row) }
      end
    end

    private

    def view_count(date, row)
      return unless row["label"].end_with?(VIEW_LABEL_SUFFIX)

      ViewCount.new(
        name: row["label"].delete_suffix(VIEW_LABEL_SUFFIX),
        date: date,
        views: Integer(row["nb_events"]),
        visits: Integer(row["nb_visits"])
      )
    end

    # Every parameter goes in the POST body, the token too: it stays out of
    # URLs and access logs, and Matomo 5 accepts secure-only tokens only there.
    def request(**params)
      body = connection.post(
        "index.php",
        module: "API",
        format: "JSON",
        idSite: @configuration.site_id,
        token_auth: @configuration.token_auth,
        **params
      ).body
      # A body that isn't JSON, such as an HTML page, stays a String.
      raise Error, "Matomo #{params[:method]} answered with no JSON report" unless body.is_a?(Hash)
      # Matomo answers 200 with an error result, for example to a wrong token.
      raise Error, "Matomo #{params[:method]} failed: #{body["message"]}" if body["result"] == "error"

      body
    rescue Faraday::Error => e
      raise Error, "Matomo #{params[:method]} failed: #{e.message}"
    end

    def connection
      @connection ||=
        Faraday.new(@configuration.url) do |conn|
          conn.request :url_encoded
          conn.response :raise_error
          conn.response :json
          conn.options.open_timeout = OPEN_TIMEOUT
          conn.options.timeout = READ_TIMEOUT
        end
    end
  end
end
