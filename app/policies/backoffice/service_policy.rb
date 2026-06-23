# frozen_string_literal: true

class Backoffice::ServicePolicy < Backoffice::ApplicationPolicy
  class Scope < Backoffice::ApplicationPolicy::Scope
    def resolve
      if user&.coordinator? || user&.data_administrator?
        super
      elsif user&.service_owner?
        scope.includes(:service_user_relationships).where(service_user_relationships: { user: user })
      else
        scope.none
      end
    end
  end

  MP_INTERNAL_FIELDS = [
    :type,
    :status,
    :upstream_id,
    [owner_ids: []],
    [sources_attributes: %i[id source_type eid _destroy]]
  ].freeze

  def index?
    coordinator? || service_owner? || data_administrator?
  end

  def show?
    actionable?
  end

  def new?
    coordinator? || user&.data_administrator?
  end

  def create?
    access?
  end

  def edit?
    access?
  end

  def update?
    access?
  end

  def publish?
    actionable? && !record.published?
  end

  def suspend?
    actionable? && !record.suspended?
  end

  def unpublish?
    actionable? && !record.unpublished?
  end

  def draft?
    actionable? && !record.draft?
  end

  def preview?
    access?
  end

  def destroy?
    access?
  end

  def permitted_attributes
    attrs = [
      :type,
      :name,
      :description,
      :order_type,
      :publishing_date,
      :resource_type,
      :node_ids,
      [provider_ids: []],
      [urls: []],
      [public_contact_emails: []],
      :terms_of_use_url,
      :access_policies_url,
      :webpage_url,
      :privacy_policy_url,
      :order_url,
      [access_type_ids: []],
      :logo,
      [trl_ids: []],
      [scientific_domain_ids: []],
      :tag_list,
      [category_ids: []],
      [pc_category_ids: []],
      :catalogue,
      :catalogue_id,
      [owner_ids: []],
      :status,
      :upstream_id,
      :resource_organisation_id,
      :version_control,
      # Datasource content
      :jurisdiction_id,
      :datasource_classification_id,
      [research_product_types: []],
      :thematic,
      [sources_attributes: %i[id source_type eid _destroy]],
      [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
    ]

    !@record.is_a?(Service) || @record.upstream.nil? ? attrs : MP_INTERNAL_FIELDS
  end

  private

  def service_owner?
    user&.service_owner?
  end

  def project_items
    ProjectItem.joins(:offer).where(offers: { orderable_type: "Service", orderable_id: record.id })
  end
end
