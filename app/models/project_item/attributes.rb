# frozen_string_literal: true

class ProjectItem::Attributes
  attr_reader :offer, :bundle, :attributes

  def initialize(offer:, parameters: nil)
    @offer = offer
    parameters = @offer.parameters.map(&:dump) if parameters.blank?
    @attributes = attributes_from_params(parameters)
  end

  def update(values)
    values.each { |id, value| update_attribute(id, value) }
  end

  def to_json(*_args)
    attributes.map(&:to_json)
  end

  private

  def attributes_from_params(parameters)
    parameters.map do |parameter|
      Attribute.from_json(parameter).tap { |attr| attr.value = default_value(parameter) if attr.value.nil? }
    end
  end

  # Each order of a deployable service gets its own DNS name, so it is generated here instead of stored with the offer
  def default_value(parameter)
    return dns_name if offer.deployable_service && DeployableService::DnsName.input?(parameter["id"])

    parameter["default_value"]
  end

  def dns_name
    @dns_name ||= DeployableService::DnsName.generate
  end

  def update_attribute(id, value)
    attributes_hsh[id]&.value_from_param(value)
  end

  def attributes_hsh
    @attributes_hsh ||= attributes.index_by(&:id)
  end
end
