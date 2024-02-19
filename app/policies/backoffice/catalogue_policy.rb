# frozen_string_literal: true

class Backoffice::CataloguePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

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
      [tags: []],
      :street_name_and_number,
      :postal_code,
      :city,
      :region,
      :country,
      [participating_countries: []],
      [affiliations: []],
      [network_ids: []],
      [sources_attributes: %i[id source_type eid _destroy]],
      [main_contact_attributes: %i[id first_name last_name email phone organisation position]],
      [public_contacts_attributes: %i[id first_name last_name email phone organisation position _destroy]],
      [data_administrators_attributes: %i[id first_name last_name email _destroy]],
      [link_multimedia_urls_attributes: %i[id name url _destroy]]
    ]
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end
end
