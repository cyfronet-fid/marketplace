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
      f.use HttpMiddleware::SsrfProtection
      f.use HttpMiddleware::ResponseSizeLimit, max: MAX_SIZE
      f.adapter HttpMiddleware::SsrfProtection::NetHttp
    end
  end

  # https://github.com/<owner>/<repo>/blob/<ref>/<path> -> https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>
  def raw_github_url(url)
    uri = URI.parse(url)
    blob_path = %r{\A(/[^/]+/[^/]+)/blob/}
    return url unless uri.host == "github.com" && uri.path.match?(blob_path)

    uri.host = "raw.githubusercontent.com"
    uri.path = uri.path.sub(blob_path, '\1/')
    uri.to_s
  end
end
