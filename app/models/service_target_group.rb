# frozen_string_literal: true

class ServiceTargetGroup < ApplicationRecord
  belongs_to :service
  belongs_to :target_group

  validates :service, presence: true
  validates :target_group, presence: true, uniqueness: { scope: :service_id }
end
