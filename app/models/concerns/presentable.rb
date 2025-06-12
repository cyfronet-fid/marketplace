# frozen_string_literal: true

module Presentable
  extend ActiveSupport::Concern

  def geographical_availabilities=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def resource_geographic_locations=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def target_relationships
    (required_services + manual_related_services + related_services).uniq
  end

  def resource_organisation_and_providers
    ([resource_organisation] + Array(providers)).reject(&:blank?).uniq
  end

  def resource_organisation_name
    resource_organisation.name
  end

  def external?
    order_required? && order_url.present?
  end

  def providers?
    providers.reject(&:blank?).reject { |p| p == resource_organisation }.size.positive?
  end

  def available_omses
    (OMS.where(default: true).to_a + omses.to_a + OMS.where(type: :global).to_a + resource_organisation&.omses).uniq
  end
end
