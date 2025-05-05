# frozen_string_literal: true

require "faraday_middleware"

class Importers::Request
  def initialize(eosc_registry_base_url, suffix, faraday: Faraday, token: nil, id: nil)
    @eosc_registry_base_url = eosc_registry_base_url
    @suffix = suffix
    @token = "Bearer #{token}"
    @id = id
    @conn = api_client_connection(faraday, @token)
  end

  def call
    request = @id.blank? ? all : specific
    raise Errno::ECONNREFUSED if request.blank? || request.status != 200
    request
  end

  private

  def all
    command = @suffix == "vocabulary/byType" ? nil : "all?quantity=10000&from=0"
    command = "all?catalogue_id=all" if @suffix == "resourceInteroperabilityRecord"
    url = "#{@eosc_registry_base_url}/#{@suffix}"
    url += "/#{command}" if command.present?
    @conn.get(url)
  end

  def specific
    @conn.get("#{@eosc_registry_base_url}/#{@suffix}/#{@id}")
  end

  def api_client_connection(faraday, authorization_header = nil)
    faraday.new do |f|
      f.request :url_encoded
      f.request :multipart
      f.request :json # encode req bodies as JSON
      f.request :retry # retry transient failures
      f.response :follow_redirects # follow redirects
      f.response :json # decode response bodies as JSON
      f.headers["Authorization"] = authorization_header unless authorization_header.blank?
      f.adapter Faraday.default_adapter
    end
  end
end
