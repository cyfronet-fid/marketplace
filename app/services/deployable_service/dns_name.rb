# frozen_string_literal: true

# Unique DNS names (<uuid>.vm.fedcloud.eu) for the DNS inputs of deployed TOSCA templates.
# Users cannot choose their own name: only a value in the generated format is accepted from the order form.
module DeployableService::DnsName
  INPUTS = %w[kube_public_dns_name public_dns_name dns_name].freeze
  DOMAIN = "vm.fedcloud.eu"
  FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.vm\.fedcloud\.eu\z/

  def self.input?(id)
    INPUTS.include?(id.to_s)
  end

  def self.generate
    "#{SecureRandom.uuid}.#{DOMAIN}"
  end

  def self.generated?(value)
    FORMAT.match?(value.to_s)
  end
end
