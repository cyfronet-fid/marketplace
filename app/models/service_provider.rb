# frozen_string_literal: true

class ServiceProvider < ApplicationRecord
  belongs_to :provider
  belongs_to :service

  validates :provider, presence: true, uniqueness: { scope: :service_id }
  validates :service, presence: true
end
