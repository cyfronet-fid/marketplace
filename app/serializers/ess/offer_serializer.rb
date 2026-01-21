# frozen_string_literal: true

class Ess::OfferSerializer < ApplicationSerializer
  attributes :id,
             :iid,
             :name,
             :description,
             :tag_list,
             :eosc_if,
             :status,
             :order_type,
             :internal,
             :voucherable,
             :parameters,
             :updated_at

  # Resource ID (service or deployable_service) - uses polymorphic orderable
  # Include orderable_type to allow ESS to differentiate between Service and DeployableService
  attribute :orderable_id, key: :service_id
  attribute :orderable_type

  attribute :created_at, key: :publication_date

  attribute :project_items_count, key: :usage_counts_downloads
  attribute :usage_counts_views
end
