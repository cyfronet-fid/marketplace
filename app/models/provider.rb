# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :service_categories, through: :services
  has_many :categories, through: :service_categories

  validates :name, presence: true

  has_many :sources, source: :provider_sources, class_name: "ProviderSource", dependent: :destroy

  accepts_nested_attributes_for :sources,
                                reject_if: lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true
end
