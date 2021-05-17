# frozen_string_literal: true

class Backoffice::ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  MP_INTERNAL_FIELDS = [
    :upstream_id,
    sources_attributes: [:id, :source_type, :eid, :_destroy]
  ]

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

  def update?
    service_portfolio_manager?
  end

  def destroy?
    service_portfolio_manager?
  end

  def permitted_attributes
    attrs = [
      :name, :abbreviation, :website,
      :legal_entity, [legal_status_ids: []],
      :legal_status, :esfri_type, :provider_life_cycle_status,
      :description, [multimedia: []], :logo,
      [scientific_domain_ids: []], [tag_list: []], [tags: []],
      :street_name_and_number, :postal_code,
      :city, :region, :country,
      [provider_life_cycle_status_ids: []], [certifications: []],
      :hosting_legal_entity, [participating_countries: []], [affiliations: []], [network_ids: []],
      [structure_type_ids: []], [esfri_type_ids: []], [esfri_domain_ids: []], [meril_scientific_domain_ids: []],
      :upstream_id,
      [areas_of_activity_ids: []], [societal_grand_challenge_ids: []], [national_roadmaps: []],
      sources_attributes: [:id, :source_type, :eid, :_destroy],
      main_contact_attributes: [:id, :first_name, :last_name, :email, :phone, :organisation, :position],
      public_contacts_attributes: [:id, :first_name, :last_name, :email, :phone, :organisation, :position, :_destroy],
      data_administrators_attributes: [:id, :first_name, :last_name, :email, :_destroy]
    ]

    if !@record.is_a?(Provider) || @record.upstream.nil?
      attrs
    else
      attrs & MP_INTERNAL_FIELDS
    end
  end

  private
    def service_portfolio_manager?
      user&.service_portfolio_manager?
    end
end
