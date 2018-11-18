# frozen_string_literal: true

class ServiceRelatedPlatform < ApplicationRecord
  belongs_to :service
  belongs_to :platform

  validates :service, presence: true, uniqueness: { scope: :platform_id }
  validates :platform, presence: true
end
