# frozen_string_literal: true

class DeployableService::FetchTemplate < ApplicationService
  def initialize(url)
    super()
    @url = url
  end

  def call
    uri = URI.parse(raw_github_url(@url))
    response = Net::HTTP.get_response(uri)

    return response.body if response.is_a?(Net::HTTPSuccess)

    raise Net::HTTPError.new("HTTP #{response.code} #{response.message}", response)
  end

  private

  def raw_github_url(url)
    url.sub("github.com", "raw.githubusercontent.com").sub("/blob/", "/")
  end
end
