# frozen_string_literal: true

class DeployableService::FetchTemplate < ApplicationService
  MAX_REDIRECTS = 3

  def initialize(url)
    super()
    @url = url
  end

  def call
    connection.get(raw_github_url(@url)).body
  end

  private

  def connection
    Faraday.new do |f|
      f.response :raise_error # raise Faraday::Error on 4xx/5xx
      f.response :follow_redirects, limit: MAX_REDIRECTS, callback: method(:validate_redirect)
      f.adapter Faraday.default_adapter
    end
  end

  def raw_github_url(url)
    url.sub("github.com", "raw.githubusercontent.com").sub("/blob/", "/")
  end

  # Only absolute http(s) URLs with a host are followed
  def validate_redirect(_response_env, redirect_env)
    target = redirect_env[:url]
    return if target.is_a?(URI::HTTP) && target.host.present?

    raise Faraday::Error, "Invalid redirect location: #{target}"
  end
end
