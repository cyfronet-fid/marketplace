# frozen_string_literal: true

class Presentable::DetailsComponent < ApplicationComponent
  include Presentable::DetailsStyleHelper
  include Presentable::LinksHelper
  include PresentableHelper
  include SearchLinksHelper
  include ServiceHelper

  def initialize(
    object,
    similar_services: nil,
    related_services: nil,
    preview: false,
    question: nil,
    guidelines: false,
    from: nil
  )
    super()
    @object = object
    @guidelines = guidelines
    @preview = preview
    @similar_services = similar_services
    @related_services = related_services
    @question = question
    @from = from
  end

  def deployable_application?
    resource_type == "DeployableApplication"
  end

  def service?
    resource_type.casecmp?("service")
  end

  def catalogue?
    @object.is_a?(Catalogue)
  end

  def provider?
    @object.is_a?(Provider)
  end

  def sqa_entries
    metadata_entries(:sqa)
  end

  def keywords
    metadata_entries(:keywords)
  end

  def persistent_identifiers
    return [] unless service? || provider?

    metadata_entries(:alternative_identifiers)
  end

  def learning_outcomes
    metadata_entries(:learning_outcomes)
  end

  def configuration_templates
    entries = metadata_entries(:configuration_templates, :configuration_template)
    return entries if entries.present? || !deployable_application?

    [{ pid: @object.pid, url: @object.url }] if @object.pid.present?
  end

  def metadata_value(entry, *attributes)
    return entry if attributes.empty?

    attributes.each do |attribute|
      value =
        if entry.is_a?(Hash)
          entry[attribute] || entry[attribute.to_s]
        elsif entry.respond_to?(attribute)
          entry.public_send(attribute)
        end
      return value if value.present?
    end

    nil
  end

  def valid_url?(url)
    ::UrlHelper.url?(url)
  end

  private

  def metadata_entries(*attributes)
    attribute =
      attributes.find { |candidate| @object.respond_to?(candidate) && @object.public_send(candidate).present? }
    attribute ? Array.wrap(@object.public_send(attribute)).compact_blank : []
  end

  def resource_type
    @object.respond_to?(:resource_type) ? @object.resource_type.to_s : ""
  end
end
