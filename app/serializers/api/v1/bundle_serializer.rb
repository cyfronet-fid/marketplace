# frozen_string_literal: true

class Api::V1::BundleSerializer < ApplicationSerializer
  attribute :iid, key: :id
  attributes :name,
             :description,
             :order_type,
             :main_offer_id,
             :bundle_goals,
             :capabilities_of_goals,
             :offer_ids,
             :contact_email,
             :helpdesk_url,
             :related_training
  attribute :related_training_url, if: -> { object.related_training.true? }
  attribute :internal, if: -> { object.order_required? }
end
