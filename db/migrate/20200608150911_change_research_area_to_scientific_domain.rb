# frozen_string_literal: true

class ChangeResearchAreaToScientificDomain < ActiveRecord::Migration[6.0]
  def change
    remove_index :service_research_areas, name: :index_service_research_areas_on_service_id_and_research_area_id
    remove_index :project_research_areas, name: :index_project_research_areas_on_project_id_and_research_area_id
    remove_index :user_research_areas, name: :index_user_research_areas_on_user_id_and_research_area_id

    rename_table :research_areas, :scientific_domains
    rename_table :service_research_areas, :service_scientific_domains
    rename_table :project_research_areas, :project_scientific_domains
    rename_table :user_research_areas, :user_scientific_domains

    rename_column :service_scientific_domains, :research_area_id, :scientific_domain_id
    rename_column :project_scientific_domains, :research_area_id, :scientific_domain_id
    rename_column :user_scientific_domains, :research_area_id, :scientific_domain_id
    rename_column :users, :research_areas_updates, :scientific_domains_updates

    add_index :service_scientific_domains,
              %i[service_id scientific_domain_id],
              unique: true,
              name: "index_ssd_on_service_id_and_sd_id"
    add_index :project_scientific_domains,
              %i[project_id scientific_domain_id],
              unique: true,
              name: "index_psd_on_service_id_and_sd_id"
    add_index :user_scientific_domains,
              %i[user_id scientific_domain_id],
              unique: true,
              name: "index_usd_on_service_id_and_sd_id"
  end
end
