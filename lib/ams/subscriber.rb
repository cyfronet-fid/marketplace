# frozen_string_literal: true

require "json"
require "yaml"
require "sentry-ruby"
require "net/http"
require "uri"
require "base64"

module Ams
end

class Ams::Subscriber
  include ConfigLoaderHelper

  CONFIG_SCHEMA = {
    type: "object",
    properties: {
      subscriptions: {
        type: "array",
        items: {
          type: "object",
          properties: {
            mode: {
              type: "string"
            }, # "pull" | "push"
            name: {
              type: "string"
            },
            token: {
              type: "string"
            },
            topics: {
              type: "array",
              items: {
                type: "string"
              }
            },
            eosc_registry_base_url: {
              type: "string"
            },
            # pull-specific
            pull_url: {
              type: "string"
            },
            poll_interval: {
              type: "number"
            },
            max_messages: {
              type: "integer"
            },
            # push-specific (for built-in handler)
            push_host: {
              type: "string"
            },
            push_port: {
              type: "integer"
            },
            push_path: {
              type: "string"
            },
            # common routing helpers
            destination_prefix: {
              type: "string"
            }
          }
        }
      },
      default_poll_interval: {
        type: "number"
      },
      eosc_registry_base_url: {
        type: "string"
      },
      token: {
        type: "string"
      }
    }
  }.freeze

  class ConnectionError < StandardError
    def initialize(msg)
      super
      Sentry.capture_exception(self)
    end
  end

  def initialize(config_file_path = nil, poll_interval: nil, logger: Logger.new("#{Rails.root}/log/ams.log"))
    @logger = logger
    @config_file_path = config_file_path
    @config = load_config(default_config: :ams_subscriber)
    @stop_requested = false
    @threads = []
    # Global override for pull interval
    @global_poll_interval = (poll_interval || ENV.fetch("AMS_POLL_INTERVAL", nil))&.to_f
    $stdout.sync = true
  end

  def run
    log "Starting AMS subscriber with #{@config[:subscriptions]&.length || 0} subscriptions"

    return log "No subscriptions configured" if @config[:subscriptions].blank?

    @config[:subscriptions].each_with_index do |subscription, index|
      mode = (subscription[:mode] || "pull").to_s
      topics = subscription[:topics] || [nil]

      topics.each do |topic|
        @threads << Thread.new do
          Thread.current.name = "AMS-Sub-#{index}-#{mode}-#{topic || "all"}"
          if mode == "pull"
            pull_loop(subscription, destination_prefix: subscription[:destination_prefix], topic: topic)
          elsif mode == "push"
            start_push_handler(subscription)
          else
            log "Unknown mode '#{mode}' for subscription #{subscription[:name] || index}, skipping"
          end
        end
      end
    end

    log "All AMS subscription threads started, waiting for completion..."
    @threads.each(&:join)
  rescue StandardError => e
    @logger.error("AMS subscriber crashed: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
    Sentry.capture_exception(e)
    raise
  end

  def stop
    @stop_requested = true
    @threads.each { |t| t.kill if t&.alive? }
  end

  # ============ Pull mode ============
  def pull_loop(subscription, destination_prefix: nil, topic: nil)
    url = subscription[:pull_url]
    raise ArgumentError, "pull_url must be provided for pull subscription" if url.blank?

    # If topic is provided, we append it to the URL assuming pull_url is the project base
    # Format: projects/{project}/subscriptions/{sub}
    # We assume subscription name is the same as topic name for simplicity,
    # or it's a direct URL if no topic is provided.
    if topic.present?
      # Ensure url ends with /
      url += "/" unless url.end_with?("/")
      url = "#{url}#{destination_prefix}/subscriptions/#{topic}:pull"
    end

    poll_interval = (@global_poll_interval || subscription[:poll_interval] || @config[:default_poll_interval] || 5).to_f
    max_messages = (subscription[:max_messages] || 10).to_i

    log "Starting pull loop for #{topic || subscription[:name] || url} with interval #{poll_interval}m"

    until @stop_requested
      begin
        messages = pull_messages(url, max_messages, subscription)
        if messages.any?
          log "Pulled #{messages.length} message(s) from #{url}"
          messages.each { |msg| handle_ams_message(msg, subscription, topic: topic) }
          acknowledge_messages(url, messages.map { |m| m[:ack_id] }.compact, subscription)
        end
      rescue StandardError => e
        @logger.error("Pull error for #{url}: #{e.message}")
        @logger.error(e.backtrace.join("\n"))
        Sentry.capture_exception(e)
        sleep 2
      ensure
        sleep poll_interval * 60
      end
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def pull_messages(url, max_messages, subscription)
    # Minimal generic implementation compatible with Google Pub/Sub-style pull
    # If your AMS endpoint differs, adjust accordingly in config to point to a small
    # middleware that translates to Pub/Sub.
    uri = URI.parse(url)

    req_body = { maxMessages: max_messages.to_s, returnImmediately: "true" }.to_json
    headers = { "Content-Type" => "application/json" }
    headers["x-api-key"] = "#{subscription[:token] || @config[:token]}" if (
      subscription[:token] || @config[:token]
    ).present?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    if http.use_ssl?
      # On some systems OpenSSL is configured to require CRL, which can fail
      # if the CRL is not available. We explicitly provide a clean cert store.
      store = OpenSSL::X509::Store.new
      store.set_default_paths
      http.cert_store = store
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = req_body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise ConnectionError, "Pull request failed: #{response.code} #{response.message}"
    end

    begin
      data = JSON.parse(response.body)
    rescue JSON::ParserError
      data = {}
    end

    received = data["receivedMessages"] || []
    # Normalize to a simple array of Hashes with { body:, attributes: }
    received.map do |rm|
      message = rm["message"] || {}
      data = message["data"] || message["body"]
      body =
        begin
          data.present? ? Base64.decode64(data.to_s) : rm.to_json
        rescue StandardError
          data || rm.to_json
        end

      { body: body, attributes: message["attributes"] || {}, ack_id: rm["ackId"] }
    end
  rescue Errno::ECONNREFUSED, SocketError => e
    raise ConnectionError, e.message
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def acknowledge_messages(url, ack_ids, subscription)
    return if ack_ids.empty?

    # url ends with :pull, we need to replace it with :acknowledge
    ack_url = url.sub(/:pull$/, ":acknowledge")
    uri = URI.parse(ack_url)

    req_body = { ackIds: ack_ids }.to_json
    headers = { "Content-Type" => "application/json" }
    headers["x-api-key"] = "#{subscription[:token] || @config[:token]}" if (
      subscription[:token] || @config[:token]
    ).present?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    if http.use_ssl?
      store = OpenSSL::X509::Store.new
      store.set_default_paths
      http.cert_store = store
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = req_body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      @logger.error("Acknowledge request failed for #{ack_url}: #{response.code} #{response.message}")
    end
  rescue StandardError => e
    @logger.error("Error sending acknowledge to #{ack_url}: #{e.message}")
    Sentry.capture_exception(e)
  end

  # ============ Push mode ============
  def start_push_handler(subscription)
    require "webrick"

    host = subscription[:push_host] || "0.0.0.0"
    port = (subscription[:push_port] || 9294).to_i
    path = subscription[:push_path] || "/ams/push"
    token = subscription[:token] || @config[:token]

    log "Starting simple push HTTP handler on #{host}:#{port}#{path}"

    server = WEBrick::HTTPServer.new(Host: host, Port: port, AccessLog: [], Logger: WEBrick::Log.new(File::NULL))

    server.mount_proc(path) do |req, res|
      if token.present?
        auth = req["Authorization"] || req["X-Auth"]
        unless auth.to_s.include?(token)
          res.status = 401
          res.body = "unauthorized"
          next
        end
      end

      payload = req.body.to_s
      # If payload is a JSON containing AMS message structure, decode the data part
      begin
        parsed_payload = JSON.parse(payload)
        if parsed_payload.is_a?(Hash) && parsed_payload["message"] && parsed_payload["message"]["data"]
          payload = Base64.decode64(parsed_payload["message"]["data"].to_s)
        end
      rescue JSON::ParserError
        # Not a JSON, use raw payload
      end

      attributes =
        begin
          JSON.parse(req["x-ams-attributes"] || "{}")
        rescue StandardError
          {}
        end
      handle_ams_message({ body: payload, attributes: attributes }, subscription, topic: topic)
      res.status = 204
      res.body = ""
    rescue StandardError => e
      @logger.error("Push handler error: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
      Sentry.capture_exception(e)
      res.status = 500
      res.body = "error"
    end

    trap("INT") { server.shutdown }
    trap("TERM") { server.shutdown }

    server.start
  end

  # ============ Common processing ============
  def handle_ams_message(msg_hash, _subscription, topic: nil)
    # msg_hash: { body:, attributes:, ack_id? }
    message = msg_hash[:body]

    Ams::ManageMessage.call(message, topic, @config[:eosc_registry_base_url], @logger)
  rescue StandardError => e
    error_block(e, topic)
  end

  def build_destination(subscription, attributes, topic: nil)
    # Try to reconstruct a destination-like string used by AMS ManageMessage
    # Prefer explicit attribute if provided, otherwise fall back to helper fields
    return attributes["destination"] if attributes && attributes["destination"].present?

    prefix = subscription[:destination_prefix].presence

    # If topic is provided, try to extract model and action from it: mp-${model}-${action}
    if topic.present?
      parts = topic.split("-")
      if parts.size >= 3 && parts[0] == "mp"
        action = parts.last
        model = parts[1...-1].join("-")
        return "#{prefix}.#{model}.#{action}"
      end
    end

    # Fallback to attributes if topic extraction fails
    resource = attributes["resource"] || attributes["type"]
    action = attributes["action"] || attributes["event"]

    # Fallback if attributes are missing (e.g. raw message without metadata)
    resource ||= "unknown"
    action ||= "update"

    "#{prefix}.#{resource}.#{action}"
  end

  def error_block(error, destination)
    @logger.error("Error processing AMS message for #{destination}: #{error.message}")
    @logger.error(error.backtrace.join("\n")) if error.backtrace
    Sentry.capture_exception(error)
  end

  def log(msg)
    @logger.info(msg)
  end

  def config_schema
    CONFIG_SCHEMA
  end
end
