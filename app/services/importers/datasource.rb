# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data, source = "jms")
    super()
    @data = data
    @source = source
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def call
    persistent_identity_systems = Array(@data["persistentIdentitySystems"] || [])
    link_rpl_url =
      if @data["researchProductLicensings"].is_a?(Array)
        @data["researchProductLicensings"]
      else
        [@data["researchProductLicensings"]] || []
      end
    link_rpml_url =
      if @data["researchProductMetadataLicensing"].is_a?(Array)
        @data["researchProductMetadataLicensing"]
      else
        [@data["researchProductMetadataLicensing"]] || []
      end
    entity_types = map_entity_types(Array(@data["researchEntityTypes"]) || [])
    research_product_access_policies = @data["researchProductMetadataAccessPolicies"] || []
    research_product_metadata_access_policies = @data["researchProductMetadataAccessPolicies"] || []

    {
      # Datasource policies
      submission_policy_url: @data["submissionPolicyURL"] || "",
      preservation_policy_url: @data["preservationPolicyURL"] || "",
      version_control: @data["versionControl"] || false,
      persistent_identity_systems:
        persistent_identity_systems&.map { |s| map_persistent_identity_system(s, @source) }&.compact || [],
      # Datasource content
      jurisdiction: map_jurisdiction(@data["jurisdiction"]) || nil,
      datasource_classification: map_datasource_classification(@data["datasourceClassification"]) || nil,
      research_entity_types: entity_types,
      thematic: @data["thematic"],
      harvestable: @data["harvestable"],
      # Research product policies
      link_research_product_license_urls:
        link_rpl_url&.map { |item| map_link(item, "research_product") }&.compact || [],
      research_product_access_policies: map_access_policies(research_product_access_policies) || [],
      # Research Product Metadata
      link_research_product_metadata_license_urls:
        link_rpml_url&.map { |item| map_link(item, "research_product_metadata") }&.compact || [],
      research_product_metadata_access_policies:
        map_metadata_access_policies(research_product_metadata_access_policies) || []
    }
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
