# frozen_string_literal: true

class Ess::ServiceSerializer < ApplicationSerializer
  attribute :slug, unless: :datasource?

  attributes :id,
             :pid,
             :ppid,
             :name,
             :description,
             :webpage_url,
             :urls,
             :logo,
             :scientific_domains,
             :categories,
             :tag_list,
             :access_types,
             :trls,
             :jurisdiction,
             :terms_of_use_url,
             :privacy_policy_url,
             :access_policies_url,
             :order_type,
             :order_url,
             :resource_organisation,
             :providers,
             :nodes,
             :guidelines,
             :public_contact_emails,
             :publishing_date,
             :resource_type,
             :status,
             :upstream_id,
             :synchronized_at,
             :updated_at,
             :created_at

  attribute :created_at, key: :publication_date
  attribute :project_items_count, key: :usage_counts_downloads
  attribute :usage_counts_views

  attribute :offers_count, unless: :datasource?
  attribute :service_opinion_count, unless: :datasource?
  attribute :rating, unless: :datasource?

  def datasource?
    object.type == "Datasource"
  end

  def logo
    return nil unless object.logo.attached?

    if Rails.application.routes.default_url_options[:host].present?
      Rails.application.routes.url_helpers.service_logo_url(object)
    else
      Rails.application.routes.url_helpers.service_logo_path(object)
    end
  end

  def nodes
    object.nodes.map(&:name)
  end

  def publishing_date
    object.publishing_date&.as_json
  end
end
