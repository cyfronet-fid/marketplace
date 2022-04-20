# frozen_string_literal: true

class Backoffice::ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  MP_INTERNAL_FIELDS = [:upstream_id, [sources_attributes: %i[id source_type eid _destroy]]].freeze

  def index?
    service_portfolio_manager?
  end

  def show?
    service_portfolio_manager?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def edit?
    service_portfolio_manager? && !record.deleted?
  end

  def update?
    service_portfolio_manager? && !record.deleted?
  end

  def destroy?
    service_portfolio_manager? && !record.deleted?
  end

  def permitted_attributes
    attrs = [
      :name,
      :abbreviation,
      :website,
      :status,
      :legal_entity,
      [legal_status_ids: []],
      :legal_status,
      :esfri_type,
      :provider_life_cycle_status,
      :description,
      :logo,
      [multimedia: []],
      [scientific_domain_ids: []],
      [tag_list: []],
      :street_name_and_number,
      :postal_code,
      :city,
      :region,
      :country,
      [provider_life_cycle_status_ids: []],
      [certifications: []],
      :hosting_legal_entity,
      [participating_countries: []],
      [affiliations: []],
      [network_ids: []],
      :catalogue,
      [structure_type_ids: []],
      [esfri_type_ids: []],
      [esfri_domain_ids: []],
      [meril_scientific_domain_ids: []],
      :upstream_id,
      [area_of_activity_ids: []],
      [societal_grand_challenge_ids: []],
      [national_roadmaps: []],
      [sources_attributes: %i[id source_type eid _destroy]],
      [main_contact_attributes: %i[id first_name last_name email phone organisation position]],
      [public_contacts_attributes: %i[id first_name last_name email phone organisation position _destroy]],
      [data_administrators_attributes: %i[id first_name last_name email _destroy]],
      [link_multimedia_urls_attributes: %i[id name url _destroy]]
    ]

    !@record.is_a?(Provider) || @record.upstream_id.blank? ? attrs : attrs & MP_INTERNAL_FIELDS
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end
end
