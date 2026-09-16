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

  # pl and whitelabel inherit Backoffice::ApplicationPolicy's rules here;
  # marketplace keeps its own (access? ignores deleted records, show? does not).
  def show?
    Mp::Variant.marketplace? ? actionable? : access?
  end

  def new?
    coordinator? || user&.data_administrator?
  end

  def create?
    Mp::Variant.marketplace? ? access? : management_role?
  end

  def edit?
    Mp::Variant.marketplace? ? access? : actionable?
  end

  def update?
    Mp::Variant.marketplace? ? access? : actionable?
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
    Mp::Variant.marketplace? ? access? : actionable?
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

    # Only marketplace locks registry-imported services to their internal fields.
    !Mp::Variant.marketplace? || !@record.is_a?(Service) || @record.upstream.nil? ? attrs : MP_INTERNAL_FIELDS
  end

  private

  def service_owner?
    user&.service_owner?
  end

  def project_items
    ProjectItem.joins(:offer).where(offers: { orderable_type: "Service", orderable_id: record.id })
  end
end
