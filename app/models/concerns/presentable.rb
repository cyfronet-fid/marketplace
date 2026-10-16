# frozen_string_literal: true

module Presentable
  extend ActiveSupport::Concern

  def geographical_availabilities=(value)
    super(value&.map { |country| Country.for(country) })
  end

  def resource_organisation_and_providers
    ([resource_organisation] + Array(providers)).compact_blank.uniq
  end

  delegate :name, to: :resource_organisation, prefix: true

  def external?
    order_required? && order_url.present?
  end

  def providers?
    providers.compact_blank.reject { |p| p == resource_organisation }.size.positive?
  end

  def available_omses
    (OMS.where(default: true).to_a + omses.to_a + OMS.where(type: :global).to_a + resource_organisation&.omses).uniq
  end
end
