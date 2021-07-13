# frozen_string_literal: true

class Importers::Request
  def initialize(eosc_registry_base_url, suffix, unirest: Unirest, token: nil, id: nil)
    @eosc_registry_base_url = eosc_registry_base_url
    @suffix = suffix
    @token = token
    @id = id
    @unirest = unirest
  end

  def call
    request = @id.blank? ? all : specific
    if request.blank? || request.code != 200
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

        Unirest::HttpResponse.new(http_response)
      else
        @unirest.get("#{@eosc_registry_base_url}/#{@suffix}/#{command}",
                     headers: { "Accept" => "application/json" })
      end
    end

    def specific
      unless @token.blank?
        http_response = RestClient::Request.execute(method: :get,
                                                    url: "#{@eosc_registry_base_url}/#{@suffix}/#{@id}",
                                                    headers: { Accept: "application/json",
                                                               Authorization: "Bearer #{@token}" })

        Unirest::HttpResponse.new(http_response)
      else
        @unirest.get("#{@eosc_registry_base_url}/#{@suffix}/#{@id}",
                     headers: { "Accept" => "application/json" })
      end
    end
end
