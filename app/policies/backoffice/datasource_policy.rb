# frozen_string_literal: true

class Backoffice::DatasourcePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  MP_INTERNAL_FIELDS = [:upstream_id, [sources_attributes: %i[id source_type eid _destroy]]].freeze

  def index?
    coordinator?
  end

  def show?
    coordinator?
  end

  def new?
    coordinator?
  end

  def create?
    coordinator?
  end

  def edit?
    coordinator?
  end

  def update?
    coordinator?
  end

  def destroy?
    coordinator?
  end

  def publish?
    coordinator? && record.draft? && !record.deleted?
  end

  def draft?
    coordinator? && record.published? && !record.deleted?
  end

  def permitted_attributes
    attrs = [
      # Basic
      :name,
      :resource_organisation_id,
      [provider_ids: []],
      :webpage_url,
      :publishing_date,
      :resource_type,
      [urls: []],
      # Marketing
      :description,
      :logo,
      [public_contact_emails: []],
      # Classification
      [scientific_domain_ids: []],
      [category_ids: []],
      [access_type_ids: []],
      [tag_list: []],
      [trl_ids: []],
      [catalogue_ids: []],
      # Management
      :terms_of_use_url,
      :privacy_policy_url,
      :access_policies_url,
      # Order
      :order_type,
      :order_url,
      :version_control,
      # Datasource content
      :jurisdiction_id,
      :datasource_classification_id,
      [research_product_types: []],
      :thematic,
      # Other
      :upstream_id,
      [sources_attributes: %i[id source_type eid _destroy]],
      [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
    ]

    !@record.is_a?(Provider) || @record.upstream_id.blank? ? attrs : attrs & MP_INTERNAL_FIELDS
  end

  def data_administrator?
    record.owned_by?(user)
  end

  private

  def coordinator?
    user&.coordinator?
  end
end
