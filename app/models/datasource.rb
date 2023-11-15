# frozen_string_literal: true

class Datasource < Service
  include Rails.application.routes.url_helpers
  def self.model_name
    Service.model_name
  end

  def self.type
    "Datasource"
  end

  friendly_id :name, use: :slugged

  before_save do
    self.pid = sources&.first&.eid || abbreviation if pid.blank?
    self.persistent_identity_systems =
      persistent_identity_systems.reject { |p| p.entity_type.blank? && p.entity_type_schemes.blank? }
  end

  accepts_nested_attributes_for :persistent_identity_systems, reject_if: :all_blank, allow_destroy: true

  private

  def _provider_search_link(target_name, filter_query, default_path = nil)
    search_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search
    if enable_external_search
      search_base_url + "/search/data_source?q=*&fq=#{filter_query}:(%22#{target_name}%22)"
    else
      default_path || provider_path(self)
    end
  end
end
