# frozen_string_literal: true

class Ess::OfferSerializer < ApplicationSerializer
  attributes :id,
             :iid,
             :name,
             :description,
             :service_id,
             :tag_list,
             :eosc_if,
             :status,
             :order_type,
             :internal,
             :voucherable,
             :parameters,
             :updated_at

  attribute :created_at, key: :publication_date

  attribute :project_items_count, key: :usage_counts_downloads
  attribute :usage_counts_views
end
