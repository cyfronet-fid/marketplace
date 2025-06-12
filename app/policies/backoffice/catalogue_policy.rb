# frozen_string_literal: true

class Backoffice::CataloguePolicy < Backoffice::ApplicationPolicy
  def index?
    coordinator? || user&.catalogue_owner?
  end

  def permitted_attributes
    [
      :name,
      :abbreviation,
      :website,
      :status,
      :legal_entity,
      :hosting_legal_entity,
      :legal_status,
      :inclusion_criteria,
      :validation_process,
      :end_of_life,
      :scope,
      :upstream_id,
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
      [participating_countries: []],
      [affiliations: []],
      [network_ids: []],
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
      [link_multimedia_urls_attributes: %i[id name url _destroy]]
    ]
  end
end
