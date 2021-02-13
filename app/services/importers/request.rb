# frozen_string_literal: true

class Importers::Request
  def initialize(eic_base_url, suffix, unirest: Unirest, token: nil, id: nil)
    @eic_base_url = eic_base_url
    @suffix = suffix
    @token = token
    @id = id
    @unirest = unirest
  end

  def call
    request = @id.blank? ? all : specific
    if request.code != 200
      raise Errno::ECONNREFUSED
    end
    request
  end

  private
    def all
      unless @token.blank?
        http_response = RestClient::Request.execute(method: :get,
                                                    url: "#{@eic_base_url}/#{@suffix}/all?quantity=10000&from=0",
                                                    headers: { Accept: "application/json",
                                                               Authorization: "Bearer #{@token}" })

        Unirest::HttpResponse.new(http_response)
      else
        @unirest.get("#{@eic_base_url}/#{@suffix}/all?quantity=10000&from=0",
                     headers: { "Accept" => "application/json" })
      end
    end

    def specific
      unless @token.blank?
        http_response = RestClient::Request.execute(method: :get,
                                                    url: "#{@eic_base_url}/#{@suffix}/#{@id}",
                                                    headers: { Accept: "application/json",
                                                               Authorization: "Bearer #{@token}" })

        Unirest::HttpResponse.new(http_response)
      else
        @unirest.get("#{@eic_base_url}/#{@suffix}/#{@id}",
                     headers: { "Accept" => "application/json" })
      end
    end
end
