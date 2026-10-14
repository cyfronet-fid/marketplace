# frozen_string_literal: true

class DeployableService::FetchTemplate < ApplicationService
  MAX_REDIRECTS = 3
  MAX_SIZE = 1.megabyte
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 15

  def initialize(url)
    super()
    @url = url
  end

  def call
    connection.get(raw_github_url(@url)).body
  end

  private

  def connection
    Faraday.new(request: { open_timeout: OPEN_TIMEOUT, timeout: READ_TIMEOUT }) do |f|
      f.proxy = nil # ignore proxies from the environment - SsrfProtection rejects proxied requests
      f.response :raise_error # raise Faraday::Error on 4xx/5xx
      f.response :follow_redirects, limit: MAX_REDIRECTS # before SsrfProtection, so every redirect hop is checked
      f.use Faraday::SsrfProtection
      f.use Faraday::ResponseSizeLimit, max: MAX_SIZE
      f.adapter Faraday::SsrfProtection::NetHttp
    end
  end

  def raw_github_url(url)
    url.sub("github.com", "raw.githubusercontent.com").sub("/blob/", "/")
  end
end
