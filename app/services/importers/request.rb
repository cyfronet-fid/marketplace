# frozen_string_literal: true

class Importers::Request
  def initialize(eosc_registry_base_url, suffix, faraday: Faraday, token: nil, id: nil)
    @eosc_registry_base_url = eosc_registry_base_url
    @suffix = suffix
    @token = token
    @id = id
    @faraday = faraday
  end

  def call
    request = @id.blank? ? all : specific
    if request.blank? || request.status != 200
      raise Errno::ECONNREFUSED
    end
    request
  end

  private
    def all
      command = @suffix == "vocabulary/byType" ? nil : "all?quantity=10000&from=0"
      unless @token.blank?
        http_response = RestClient::Request.execute(method: :get,
                                                    url: "#{@eosc_registry_base_url}/#{@suffix}/#{command}",
                                                    headers: { Accept: "application/json",
                                                               Authorization: "Bearer #{@token}" })

        Faraday::HttpResponse.new(http_response)
      else
        @faraday.get("#{@eosc_registry_base_url}/#{@suffix}/#{command}",
                     headers: { "Accept" => "application/json" })
      end
    end

    def specific
      unless @token.blank?
        http_response = RestClient::Request.execute(method: :get,
                                                    url: "#{@eosc_registry_base_url}/#{@suffix}/#{@id}",
                                                    headers: { Accept: "application/json",
                                                               Authorization: "Bearer #{@token}" })

        Faraday::HttpResponse.new(http_response)
      else
        @faraday.get("#{@eosc_registry_base_url}/#{@suffix}/#{@id}",
                     headers: { "Accept" => "application/json" })
      end
    end
end
