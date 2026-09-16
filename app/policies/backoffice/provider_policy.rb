# frozen_string_literal: true

class Backoffice::ProviderPolicy < Backoffice::ApplicationPolicy
  # pl and whitelabel open the backoffice provider pages to every signed-in
  # user; marketplace keeps them for coordinators and data administrators.
  def index?
    Mp::Variant.marketplace? ? management_role? : user.present?
  end

  def show?
    if Mp::Variant.pl?
      edit_permissions?
    elsif Mp::Variant.whitelabel?
      user.present?
    else
      management_role?
    end
  end

  def new?
    Mp::Variant.marketplace? ? management_role? || first_provider_registration? : user.present?
  end

  def create?
    Mp::Variant.marketplace? ? management_role? || first_provider_registration? : user.present?
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
      [node_ids: []],
      [legal_status_ids: []],
      :legal_status,
      :description,
      :logo,
      [multimedia: []],
      :country,
      [public_contact_emails: []],
      :catalogue,
      :catalogue_id,
      :upstream_id,
      [sources_attributes: %i[id source_type eid _destroy]],
      [data_administrators_attributes: %i[id first_name last_name email _destroy]],
      [link_multimedia_urls_attributes: %i[id name url _destroy]],
      [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
    ]

    # Only marketplace locks registry-imported providers to their internal fields.
    if !Mp::Variant.marketplace? || !@record.is_a?(Provider) || @record.upstream_id.blank?
      attrs
    else
      attrs & MP_INTERNAL_FIELDS
    end
  end

  private

  def catalogue_access?
    user&.catalogue_owner?
  end

  def edit_permissions?
    !record.deleted? && (coordinator? || record&.owned_by?(user))
  end

  def first_provider_registration?
    user.present? && user.providers.published.empty?
  end

  def access?
    coordinator? || (record&.owned_by?(user) && record&.approval_requests&.none?(&:published?))
  end
end
