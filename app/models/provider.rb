# frozen_string_literal: true

class Provider < ApplicationRecord
  include LogoAttachable
  extend FriendlyId
  friendly_id :pid

  acts_as_taggable

  searchkick word_middle: [:provider_name]

  def search_data
    {
      provider_name: name,
      service_ids: service_ids
    }
  end

  has_one_attached :logo

  serialize :participating_countries, Country::Array
  serialize :country, Country

  before_save :remove_empty_array_fields

  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations
  has_many :provider_data_administrators
  has_many :provider_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :provider_scientific_domains
  has_many :data_administrators, through: :provider_data_administrators, dependent: :destroy, autosave: true
  has_many :provider_vocabularies, dependent: :destroy
  has_many :legal_statuses, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::LegalStatus"
  has_many :provider_life_cycle_statuses, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::ProviderLifeCycleStatus"
  has_many :networks, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::Network"
  has_many :structure_types, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::StructureType"
  has_many :esfri_domains, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::EsfriDomain"
  has_many :esfri_types, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::EsfriType"
  has_many :meril_scientific_domains, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::MerilScientificDomain"
  has_many :areas_of_activity, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::AreaOfActivity"
  has_many :societal_grand_challenges, through: :provider_vocabularies,
           source: :vocabulary, source_type: "Vocabulary::SocietalGrandChallenge"
  has_many :oms_providers, dependent: :destroy
  has_many :oms, through: :oms_providers

  has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
  has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true

  accepts_nested_attributes_for :main_contact,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :public_contacts,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true

  has_many :sources, source: :provider_sources, class_name: "ProviderSource", dependent: :destroy

  accepts_nested_attributes_for :sources,
                                reject_if: lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :data_administrators,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates :logo, blob: { content_type: :image }
  validates :legal_statuses, length: { maximum: 1 }
  validates :provider_life_cycle_statuses, length: { maximum: 1 }
  validate :logo_variable, on: [:create, :update]

  def participating_countries=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def country=(value)
    super(Country.for(value))
  end

  def postal_code_and_city
    "#{postal_code} #{city}"
  end

  def address
    "#{street_name_and_number} <br> #{postal_code} #{city} <br> #{region} #{country}"
  end

  def services
    Service.left_joins(:service_providers).where("(status = 'unverified' OR status = 'published') AND
    (service_providers.provider_id = #{self.id} OR resource_organisation_id = #{self.id})")
  end

  private
    def remove_empty_array_fields
      array_fields = [:multimedia, :certifications, :affiliations, :national_roadmaps]
      array_fields.each do |field|
        send(field).present? ? send(:"#{field}=", send(field).reject(&:blank?)) : send(:"#{field}=", [])
      end
    end
end
