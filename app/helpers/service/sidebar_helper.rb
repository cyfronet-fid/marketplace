# frozen_string_literal: true

module Service::SidebarHelper
  def service_sidebar_fields
    [scientific_categorisation, categorisation, target_users, resource_availability_and_languages]
  end

  private
    def scientific_categorisation
      {
        name: "scientific_categorisation",
        template: "classification",
        fields: ["scientific_domains"],
        nested: {
            scientific_domains: "name"
        }
      }
    end

    def categorisation
      {
        name: "categorisation",
        template: "array",
        fields: ["pc_categories"],
        type: "tree",
        nested: {
            pc_categories: "name"
        }
      }
    end

    def target_users
      {
        name: "target_users",
        template: "array",
        fields: ["target_users"],
        nested: {
            target_users: "name"
        }
      }
    end

    def resource_availability_and_languages
      {
        name: "resource_availability_and_languages",
        template: "map",
        fields: %w[languages geographical_availabilities]
      }
    end
end
