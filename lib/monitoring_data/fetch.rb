# frozen_string_literal: true

module MonitoringData
  class Fetch
    def initialize(
      monitoring_url,
      ids: [],
      dry_run: true,
      access_token: nil,
      logger: ->(msg) { puts msg },
      faraday: Faraday,
      filepath: nil,
      start_date: 1.month.ago.beginning_of_month,
      end_date: 1.month.ago.end_of_month
    )
      @monitoring_url = monitoring_url
      @access_token = access_token
      @ids = ids
      @dry_run = dry_run
      @logger = logger
      @faraday = faraday
      @start_date = start_date.to_time.strftime("%Y-%m-%dT%H:%M:%SZ")
      @end_date = end_date.to_time.strftime("%Y-%m-%dT%H:%M:%SZ")
      @filepath = filepath
    end

    def call
      log "Import Availability/Reliability for services from #{@start_date} to #{@end_date}"

      log "IDs not provided, fetching all monitoring data #{@monitoring_url}" if @ids.blank?

      begin
        response =
          MonitoringData::Request.call(
            @monitoring_url,
            "v3/results/Default",
            start_date: @start_date,
            end_date: @end_date,
            faraday: @faraday,
            access_token: @access_token
          )
      rescue Errno::ECONNREFUSED => e
        abort("import exited with errors - could not connect to #{@monitoring_url} \n #{e.message}")
      end

      results = response.body["results"].map { |r| r["groups"] }.flatten

      File.open("log/monitoring.json", "w") { |file| file << JSON.pretty_generate(results) }

      Service
        .where(status: :published)
        .find_each do |service|
          log "Trying to find monitoring data for the service #{service.pid}"
          log "Looking under key #{service.pid.to_s.partition(".").last}"

          current_data = results.select { |r| r["name"] == service.pid.to_s.partition(".").last }.first

          if current_data.blank?
            log "Service #{service.pid} not found in the monitoring data"
            next
          end

          unless @dry_run
            current_data = current_data["results"].first
            service.update!(
              availability_cache: current_data["availability"],
              reliability_cache: current_data["reliability"]
            )
            log "Successfully updated service #{service.pid} with data: Availability: #{service.availability_cache}, " +
                  "Reliability: #{service.reliability_cache}"
          end
        end

      File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
    end

    def log(msg)
      @logger.call(msg)
    end
  end
end
