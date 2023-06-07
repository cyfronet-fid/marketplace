# frozen_string_literal: true

class Ess::OfferSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :description,
             :service_id,
             :tag_list,
             :status,
             :order_type,
             :internal,
             :voucherable,
             :parameters
end
