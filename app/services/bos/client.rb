# frozen_string_literal: true

require "faraday"
require "json"
require "uri"

class Bos::Client
  def initialize
    @bos_enabled = Rails.configuration.bos_enabled

    uri = URI.parse(Rails.configuration.bos_base_url)
    domain = "#{uri.scheme}://#{uri.host}"
    domain += ":#{uri.port}" if uri.port != uri.default_port

    raw_path = uri.path.presence || "/"
    @path = raw_path.chomp("/") == "/" ? "" : raw_path.chomp("/")

    @conn =
      Faraday.new(url: domain) do |f|
        f.request :json
        f.response :raise_error
        f.response :json, content_type: /\bjson$/
        f.headers["x-key"] = Rails.configuration.bos_api_key
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "application/json"
      end
  end

  def create_order(project_item)
    post(
      "#{@path}/api/orders",
      {
        external_ref: project_item.iid.to_s,
        project_ref: project_item.project_id.to_s,
        config: {
          params: serialize_order_params(project_item)
        },
        platforms: project_item.offer.service.platforms.map(&:name),
        resource_ref: project_item.offer.service.friendly_id,
        resource_type: project_item.offer.order_type,
        resource_name: project_item.offer.service.name,
        owner_email: project_item.user.email,
        provider_pids:
          project_item.offer.service.providers.map(&:pid).presence ||
            [project_item.offer.service.resource_organisation.pid]
      }
    )
  end

  def create_message(message)
    post(
      "#{@path}/api/messages",
      {
        content: message.message,
        scope: "public",
        user_email: message.author.email,
        order_external_ref: message.project_item.iid.to_s,
        project_external_ref: message.project_item.project_id.to_s
      }
    )
  end

  def create_user(user)
    user_type = ["mp_user"]
    user_type.push("provider_manager") if user.data_administrator?

    post("#{@path}/api/users", { name: user.full_name, email: user.email, user_type: user_type })
  end

  def create_provider(provider)
    post(
      "#{@path}/api/providers",
      {
        name: provider.name,
        website: provider.website,
        pid: provider.pid,
        manager_emails: provider.data_administrators.map(&:email)
      }
    )
  end

  private

  def post(path, body)
    unless @bos_enabled
      Rails.logger.warn("Nothing to do, BOS integration is DISABLED by an ENV variable")
      return
    end

    response = @conn.post(path) { |req| req.body = body.to_json }
    response.body
  rescue Faraday::Error => e
    Rails.logger.error("[BOS] Error calling #{path}: #{e.message}, body: #{e.response_body}")
    raise
  end

  def serialize_order_params(project_item)
    project_item.properties.map { |property| { value: property["value"], label: property["label"] } }
  end
end
