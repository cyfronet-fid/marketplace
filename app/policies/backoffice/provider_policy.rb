# frozen_string_literal: true

class Backoffice::ProviderPolicy < Backoffice::ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def new?
    user.present?
  end

  def create?
    user.present?
  end

  def edit?
    edit_permissions?
  end

  def update?
    edit_permissions?
  end

  def exit?
    user.present?
  end

  def permitted_attributes
    attrs = [
      :current_step,
      :name,
      :abbreviation,
      :website,
      :status,
      :legal_entity,
      :hosting_legal_entity,
      :hosting_legal_entity_string,
      [legal_status_ids: []],
      :legal_status,
      :esfri_type,
      :provider_life_cycle_status,
      :description,
      :logo,
      [multimedia: []],
      [scientific_domain_ids: []],
      :tag_list,
      :street_name_and_number,
      :postal_code,
      :city,
      :region,
      :country,
      [provider_life_cycle_status_ids: []],
      [certifications: []],
      [participating_countries: []],
      [affiliations: []],
      [network_ids: []],
      :catalogue,
      :catalogue_id,
      [structure_type_ids: []],
      [esfri_type_ids: []],
      [esfri_domain_ids: []],
      [esfri_domain_ids: []],
      [meril_scientific_domain_ids: []],
      :upstream_id,
      [area_of_activity_ids: []],
      [societal_grand_challenge_ids: []],
      [national_roadmaps: []],
      [sources_attributes: %i[id source_type eid _destroy]],
      [main_contact_attributes: %i[id first_name last_name email phone country_phone_code organisation position]],
      [
        public_contacts_attributes: %i[
          id
          first_name
          last_name
          email
          phone
          country_phone_code
          organisation
          position
          _destroy
        ]
      ],
      [data_administrators_attributes: %i[id first_name last_name email _destroy]],
      [link_multimedia_urls_attributes: %i[id name url _destroy]],
      [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
    ]

    !@record.is_a?(Provider) || @record.upstream_id.blank? ? attrs : attrs & MP_INTERNAL_FIELDS
  end

  private

  def catalogue_access?
    user&.catalogue_owner?
  end

  def edit_permissions?
    !record.deleted? && (coordinator? || record&.owned_by?(user))
  end

  def access?
    coordinator? || (record&.owned_by?(user) && record&.approval_requests&.none?(&:published?))
  end
end
