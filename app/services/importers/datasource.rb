# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data, source = "jms")
    super()
    @data = data
    @source = source
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def call
    case @source
    when "jms"
      link_rpl_url =
        if @data.dig("researchProductLicensings", "researchProductLicensing").is_a?(Array)
          Array(@data.dig("researchProductLicensings", "researchProductLicensing")) || []
        else
          [@data.dig("researchProductLicensings", "researchProductLicensing")] || []
        end
      link_rpml_url =
        if @data.dig("researchProductMetadataLicensings", "researchProductMetadataLicense").is_a?(Array)
          Array(@data.dig("researchProductMetadataLicensings", "researchProductMetadataLicense")) || []
        else
          [@data["researchProductMetadataLicensing"]] || []
        end
      persistent_identity_systems =
        if @data.dig("persistentIdentitySystems", "persistentIdentitySystem").is_a?(Array)
          Array(@data.dig("persistentIdentitySystems", "persistentIdentitySystem")) || []
        else
          [@data.dig("persistentIdentitySystems", "persistentIdentitySystem")] || []
        end
      entity_types = map_entity_types(@data.dig("researchEntityTypes", "researchEntityType"))
      research_product_access_policies = @data.dig("researchProductAccessPolicies", "researchProductAccessPolicy") || []
      research_product_metadata_access_policies =
        @data.dig("researchProductMetadataAccessPolicies", "researchProductMetadataAccessPolicy") || []
    when "rest"
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
    end

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

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
