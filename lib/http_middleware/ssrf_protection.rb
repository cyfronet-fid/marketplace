# frozen_string_literal: true

# Faraday middleware protecting requests to externally supplied URLs against SSRF:
#
#   Faraday.new do |f|
#     f.response :follow_redirects # before SsrfProtection, so every redirect hop is checked
#     f.use HttpMiddleware::SsrfProtection
#     f.adapter HttpMiddleware::SsrfProtection::NetHttp
#   end
#
# Only http(s) URLs without credentials whose host resolves exclusively to public addresses are allowed.
# The checked address is passed to HttpMiddleware::SsrfProtection::NetHttp, which connects to it instead of resolving
# the host again, so a second DNS answer (DNS rebinding) cannot point the request at an internal address.
class HttpMiddleware::SsrfProtection < Faraday::Middleware
  class BlockedRequestError < Faraday::Error
  end

  SCHEMES = %w[http https].freeze

  BLOCKED_RANGES = %w[
    0.0.0.0/8
    10.0.0.0/8
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.0.0.0/24
    192.0.2.0/24
    192.88.99.0/24
    192.168.0.0/16
    198.18.0.0/15
    198.51.100.0/24
    203.0.113.0/24
    224.0.0.0/4
    240.0.0.0/4
    ::/128
    ::1/128
    ::ffff:0:0/96
    64:ff9b::/96
    64:ff9b:1::/48
    100::/64
    2001::/32
    2001:db8::/32
    2002::/16
    fc00::/7
    fe80::/10
    fec0::/10
    ff00::/8
  ].map { |range| IPAddr.new(range) }.freeze

  def on_request(env)
    # A proxy would connect to the host itself, bypassing the checked address
    raise BlockedRequestError, "Proxied requests are not allowed" if env.request.proxy

    validate_url!(env.url)
    host = env.url.hostname
    env.request.context = (env.request.context || {}).merge(ssrf_target: { host: host, address: public_address(host) })
  end

  private

  def validate_url!(uri)
    return if SCHEMES.include?(uri.scheme) && uri.host.present? && uri.userinfo.nil?

    raise BlockedRequestError, "URL is not allowed"
  end

  def public_address(host)
    addresses = Addrinfo.getaddrinfo(host, nil, nil, :STREAM).map { |info| IPAddr.new(info.ip_address) }
    if addresses.empty? || addresses.any? { |address| blocked?(address) }
      raise BlockedRequestError, "URL host is not allowed"
    end

    addresses.first.to_s
  rescue SocketError, IPAddr::InvalidAddressError
    raise BlockedRequestError, "URL host could not be resolved"
  end

  def blocked?(address)
    address = address.native
    BLOCKED_RANGES.any? { |range| range.include?(address) }
  end

  # Net::HTTP adapter connecting to the address checked by SsrfProtection instead of resolving the host again.
  # The host check fails closed if the middleware did not run for this request (e.g. a redirect hop).
  class NetHttp < Faraday::Adapter::NetHttp
    def net_http_connection(env)
      target = env.request.context&.dig(:ssrf_target)
      unless target&.dig(:host) == env.url.hostname
        raise BlockedRequestError, "Request was not checked by SsrfProtection"
      end

      super.tap { |http| http.ipaddr = target[:address] }
    end
  end
end
