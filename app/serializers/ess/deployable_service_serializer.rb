# frozen_string_literal: true

class Ess::DeployableServiceSerializer < ApplicationSerializer
  attributes :id,
             :pid,
             :slug,
             :name,
             :abbreviation,
             :tagline,
             :description,
             :url,
             :urls,
             :node,
             :version,
             :publishing_date,
             :resource_type,
             :public_contact_emails,
             :license_name,
             :license_url,
             :last_update,
             :creators,
             :status,
             :resource_organisation,
             :catalogue,
             :scientific_domains,
             :tag_list,
             :upstream_id,
             :updated_at,
             :synchronized_at

  attribute :created_at, key: :publication_date

  def resource_organisation
    object.resource_organisation&.name
  end

  def catalogue
    object.catalogue&.name
  end

  def publishing_date
    object.publishing_date&.as_json
  end
end
