# frozen_string_literal: true

class Presentable::ProviderInfoComponent < ApplicationComponent
  include PresentableHelper
  def initialize(base:, preview: false)
    super()
    @base = base
    @object = base.resource_organisation
    @preview = preview
  end

  def object_fields
    {
      website: {
        type: "url"
      },
      legal_statuses: {
        type: "object",
        value: "name",
        array: true
      },
      scientific_domains: {
        type: "object",
        value: "name",
        array: true
      }
    }
  end

  def creators
    return [] unless @base.respond_to?(:creators)

    @creators ||= Array(@base.creators).map { |creator| creator_details(creator) }
  end

  private

  def creator_details(creator)
    return { name: creator } unless creator.is_a?(Hash)

    pid = creator["nameIdentifier"]
    {
      name: creator.dig("creatorNameTypeInfo", "creatorName") || creator["creatorName"] || creator["name"],
      pid: pid,
      pid_url: safe_creator_pid_url(pid),
      affiliation: creator.dig("creatorAffiliationInfo", "affiliation")
    }
  end

  def safe_creator_pid_url(creator_pid)
    uri = URI.parse(creator_pid.to_s)
    uri.to_s if uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
