# frozen_string_literal: true

# TOSCA templates name their access URL output differently (jupyterhub_url, jupyter_url, ...),
# so the first output that is an http(s) URL is used, in template declaration order (output_names),
# as the jsonb outputs column does not keep the key order. A URL with a DNS host is preferred over
# an IP address one (e.g. jupyter_dns_url over jupyter_url_ip), whose TLS certificate would not match.
class Infrastructure::SelectDeploymentUrl < ApplicationService
  def initialize(outputs, output_names = [])
    super()
    @outputs = outputs
    @output_names = output_names
  end

  def self.url?(value)
    host(value).present?
  end

  def self.dns_url?(value)
    url?(value) && !ip_address?(host(value))
  end

  def self.host(value)
    uri = URI.parse(value.to_s)
    uri.hostname if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def self.ip_address?(host)
    IPAddr.new(host)
    true
  rescue IPAddr::InvalidAddressError
    false
  end

  private_class_method :host, :ip_address?

  def call
    return if @outputs.blank?

    urls = @outputs.values_at(*(@output_names | @outputs.keys)).select { |value| self.class.url?(value) }
    urls.find { |url| self.class.dns_url?(url) } || urls.first
  end
end
