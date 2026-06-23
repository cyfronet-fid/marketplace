# frozen_string_literal: true

class Provider < ApplicationRecord
  include Approvable
  include LogoAttachable
  include ImageHelper
  include Publishable
  include Viewable
  include Propagable
  include Statusable
  include Backoffice::ProvidersHelper
  include UrlHelper
  include WizardFormModel

  extend FriendlyId
  friendly_id :pid

  searchkick word_middle: [:provider_name]

  def search_data
    { provider_id: id, provider_name: name, service_ids: service_ids, node_names: nodes.map(&:name) }
  end

  before_save { self.catalogue = Catalogue.find(catalogue_id) if catalogue_id.present? }

  scope :active, -> { where.not(status: %i[deleted draft]) }
  scope :managed_by, ->(user) { provider_managed_by(user).or(catalogue_managed_by(user)) }
  scope :provider_managed_by,
        ->(user) { includes(:data_administrators).where(data_administrators: { user_id: user&.id }) }
  scope :catalogue_managed_by, ->(user) { where(catalogues: { data_administrators: { user_id: user&.id } }) }

  attr_accessor :catalogue_id

  serialize :country, coder: Country

  has_one_attached :logo

  has_many :provider_alternative_identifiers
  has_many :alternative_identifiers, through: :provider_alternative_identifiers

  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"
  has_many :categorizations, through: :services
  has_many :bundles, foreign_key: "resource_organisation_id"
  has_many :categories, through: :categorizations
  has_many :provider_data_administrators
  has_many :data_administrators, through: :provider_data_administrators, dependent: :destroy, autosave: true
  has_many :provider_vocabularies, dependent: :destroy
  has_many :nodes, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::Node"
  has_many :hosting_legal_entities,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::HostingLegalEntity"
  has_many :legal_statuses, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::LegalStatus"
  has_many :oms_providers, dependent: :destroy
  has_many :omses, through: :oms_providers

  has_many :sources, class_name: "ProviderSource", dependent: :destroy

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ProviderSource", optional: true

  has_one :provider_catalogue, dependent: :destroy
  has_one :catalogue, through: :provider_catalogue

  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :alternative_identifiers, allow_destroy: true
  accepts_nested_attributes_for :sources, allow_destroy: true
  accepts_nested_attributes_for :data_administrators, allow_destroy: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :pid, nullify: false
  auto_strip_attributes :abbreviation, nullify: false
  auto_strip_attributes :website, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :status, nullify: false

  before_validation do
    remove_empty_array_fields
    self.legal_status = nil unless legal_entity
    self.status ||= :unpublished
  end

  with_options if: -> { required_for_step?("profile") } do
    validates :name, presence: true
    validates :abbreviation, presence: true
    validates :website, presence: true
    validates :description, presence: true
    validates :logo, blob: { content_type: :image }
    validate :valid_urls?, unless: -> { Rails.env.test? }
  end

  with_options if: -> { required_for_step?("location") } do
    validates :country, presence: true
  end

  with_options if: -> { required_for_step?("contacts") } do
    validates :public_contact_emails,
              presence: true,
              length: {
                minimum: 1,
                message: "are required. Please add at least one"
              }
  end

  with_options if: -> { required_for_step?("manager") } do
    validates :data_administrators,
              presence: true,
              length: {
                minimum: 1,
                message: "are required. Please add at least one"
              }
  end

  validate :logo_variable, on: %i[create update]
  validate :public_contact_emails_format

  def legal_status=(status_id)
    self.legal_statuses = status_id.blank? ? [] : [Vocabulary.find(status_id)]
  end

  def legal_status
    return nil if legal_statuses.blank?

    legal_statuses[0].id
  end

  def hosting_legal_entity=(entity_id)
    self.hosting_legal_entities = entity_id.blank? ? [] : [Vocabulary.find(entity_id)]
  end

  def hosting_legal_entity
    return nil if hosting_legal_entities.blank?

    hosting_legal_entities[0].id
  end

  def country=(value)
    super(Country.for(value))
  end

  def services
    Service.left_joins(:service_providers).where(
      "status = 'published' AND
    (service_providers.provider_id = #{id} OR resource_organisation_id = #{id})"
    )
  end

  def set_default_logo
    assets_path = File.join(File.dirname(__FILE__), "../assets/images")
    default_logo_name = "provider_logo.png"
    extension = ".png"
    io = File.open(assets_path + "/" + default_logo_name)

    # This should be fixed by allowing svg extension in the db
    # image = convert_to_png(io, extension)
    logo.attach(io: io, filename: SecureRandom.uuid + extension, content_type: "image/#{extension.delete(".", "")}")
  end

  def owned_by?(user)
    data_administrators&.map(&:user_id)&.include?(user&.id) ||
      (catalogue.present? && catalogue.data_administrators&.map(&:user_id)&.include?(user.id))
  end

  def valid_urls?
    if website_changed? && !UrlHelper.url_valid?(website)
      errors.add(:website, "isn't valid or website doesn't exist, please check URL")
      return false
    end
    true
  end

  def steps(*)
    basic_steps
  end

  def remove_empty_array_fields
    send(
      :data_administrators=,
      data_administrators.reject do |administrator|
        administrator.attributes["created_at"].blank? && administrator.attributes.all? { |_, value| value.blank? }
      end
    )
  end

  def public_contact_emails_format
    Array(public_contact_emails).each do |email|
      errors.add(:public_contact_emails, "#{email} is not a valid email") unless email =~ URI::MailTo::EMAIL_REGEXP
    end
  end

  def catalogue_published
    errors.add(:catalogue, "must be published") if published? && catalogue.present? && !catalogue.published?
  end

  def logo_changed?
    return false if Provider.where(id: id).blank?

    has_new_logo = logo.attached? && logo.variable?
    previous_logo = Provider.find(id).logo
    has_previous_logo = previous_logo.attached? && previous_logo.variable?

    return false if !has_previous_logo && !has_new_logo

    return true if (has_new_logo && !has_previous_logo) || (!has_new_logo && has_previous_logo)

    logo.attachment.blob != previous_logo.attachment.blob
  end
end
