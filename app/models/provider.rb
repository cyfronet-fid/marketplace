# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations
  has_many :provider_data_administrators
  has_many :data_administrators, through: :provider_data_administrators, dependent: :destroy, autosave: true

  validates :name, presence: true, uniqueness: true

  has_many :sources, source: :provider_sources, class_name: "ProviderSource", dependent: :destroy

  accepts_nested_attributes_for :sources,
                                reject_if: lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :data_administrators,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true
end
