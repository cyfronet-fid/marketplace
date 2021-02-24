# frozen_string_literal: true

module Service::DetailsHelper
  def service_details_columns
    [
      [classification, availability, marketing, dependencies, attribution, order],
      [public_contacts, maturity_information, management, financial_information],
      [changelog]
    ]
  end

  def provider_details_columns
    [
      [statuses, certifications, esfri_types_and_domains, meril_scientific_domains],
      [affiliations, structure_types, areas_of_activity, societal_grand_challenges],
      [hosting_legal_entity, networks, national_roadmaps]
    ]
  end

  def details_column_width_lg(columns)
    [4, 12 / columns.length].min
  end

  def details_column_width_md(columns)
    [6, 12 / columns.length].min
  end

  def details_column_width_sm(columns)
    12
  end

  def display_detail?(detail, service)
    (!detail[:clazz].present? && any_present?(service, *detail[:fields])) ||
      (detail[:clazz] && service.send(detail[:clazz]).present?)
  end

  def public_contacts
    {
      name: "public_contacts",
      template: "object",
      fields: %w[full_name email phone position_in_organisation],
      type: "array",
      clazz: "public_contacts",
      nested: {
        email: "email"
      }
    }
  end

  private
    def classification
      {
        name: "classification",
        template: "array",
        fields: %w[target_users access_types access_modes tag_list],
        with_desc: true,
        nested: {
            target_users: "name",
            access_types: "name",
            access_modes: "name",
            tag_list: "tag"
        }
      }
    end

    def availability
      {
        name: "availability",
        template: "array",
        fields: %w[geographical_availabilities languages],
        with_desc: true
      }
    end

    def marketing
      {
        name: "marketing",
        template: "links",
        fields: %w[multimedia use_cases_url],
        type: "array"
      }
    end

    def dependencies
      {
        name: "dependencies",
        template: "array",
        fields: %w[required_services related_services related_platforms],
        with_desc: true,
        nested: {
            required_services: "service",
            related_services: "service"
        }
      }
    end

    def attribution
      {
        name: "attribution",
        template: "array",
        fields: %w[funding_bodies funding_programs grant_project_names],
        with_desc: true,
        nested: {
            funding_bodies: "name",
            funding_programs: "name"
        }
      }
    end

    def order
      {
        name: "order",
        template: "array",
        fields: %w[order_type order_url],
        nested: {
            order_type: "label",
            order_url: "link"
        },
        with_desc: true
      }
    end

    def maturity_information
      {
        name: "maturity_information",
        template: "array",
        fields: %w[trl life_cycle_status certifications standards open_source_technologies version last_update],
        with_desc: true,
        nested: {
            trl: "name",
            life_cycle_status: "name"
        }
      }
    end

    def management
      {
        name: "management",
        template: "links",
        fields: %w[helpdesk_url manual_url terms_of_use_url privacy_policy_url access_policies_url
                   training_information_url status_monitoring_url maintenance_url],
        with_desc: true
      }
    end

    def financial_information
      {
        name: "financial_information",
        template: "links",
        fields: %w[payment_model_url pricing_url]
      }
    end

    def changelog
      {
        name: "changelog",
        template: "list",
        fields: ["changelog"]
      }
    end

    def statuses
      {
        name: "statuses",
        template: "array",
        fields: %w[legal_statuses provider_life_cycle_statuses],
        with_desc: true,
        nested: {
          legal_statuses: "name",
          provider_life_cycle_statuses: "name"
        }
      }
    end

    def esfri_types_and_domains
      {
        name: "esfri_types_and_domains",
        template: "array",
        fields: %w[esfri_types esfri_domains],
        with_desc: true,
        nested: {
          esfri_types: "name",
          esfri_domains: "name"
        }
      }
    end

    def meril_scientific_domains
      {
        name: "meril_scientific_categorisation",
        template: "list",
        fields: %w[meril_scientific_domains],
        nested: {
          meril_scientific_domains: "name_with_parent"
        }
      }
    end

    def certifications
      {
        name: "certifications",
        template: "list",
        fields: %w[certifications]
      }
    end

    def affiliations
      {
        name: "affiliations",
        template: "list",
        fields: %w[affiliations]
      }
    end

    def structure_types
      {
        name: "structure_types",
        template: "list",
        fields: %w[structure_types],
        nested: {
          structure_types: "name"
        }
      }
    end

    def areas_of_activity
      {
        name: "areas_of_activity",
        template: "list",
        fields: %w[areas_of_activity],
        nested: {
          areas_of_activity: "name"
        }
      }
    end

    def societal_grand_challenges
      {
        name: "societal_grand_challenges",
        template: "list",
        fields: %w[societal_grand_challenges],
        nested: {
          societal_grand_challenges: "name"
        }
      }
    end

    def hosting_legal_entity
      {
        name: "hosting_legal_entity",
        template: "array",
        fields: %w[hosting_legal_entity]
      }
    end

    def networks
      {
        name: "networks",
        template: "list",
        fields: %w[networks],
        nested: {
          networks: "name"
        }
      }
    end

    def national_roadmaps
      {
        name: "national_roadmaps",
        template: "list",
        fields: %w[national_roadmaps]
      }
    end
end
