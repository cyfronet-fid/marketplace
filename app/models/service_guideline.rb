# frozen_string_literal: true

class ServiceGuideline < ApplicationRecord
  belongs_to :guideline
  belongs_to :service

  validates :guideline, presence: true, uniqueness: { scope: :service_id }
  validates :service, presence: true
end
