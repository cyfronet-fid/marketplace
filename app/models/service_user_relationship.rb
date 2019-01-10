# frozen_string_literal: true

class ServiceUserRelationship < ApplicationRecord
  belongs_to :service
  belongs_to :user, counter_cache: "owned_services_count"
end
