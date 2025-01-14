# frozen_string_literal: true

class Offer < ApplicationRecord
  # TODO: validate parameter ids uniqueness - for now we are safe thanks to schema validation though
  include ActionView::Helpers::TextHelper
  include Offerable
  include Offer::Parameters
  include Propagable
  include Statusable

  acts_as_taggable

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  def search_data
    { offer_name: name, description: description, service_id: service_id, order_type: order_type }
  end

  def should_index?
    status == "published" && offers_count > 1
  end

  scope :bundle_exclusive, -> { where(bundle_exclusive: true, status: :published) }
  scope :inclusive,
        -> do
          joins(:service).where(
            bundle_exclusive: false,
            status: :published,
            services: {
              status: %i[published suspended errored]
            }
          )
        end
  scope :accessible, -> { joins(:service).where(status: :published, services: { status: Statusable::PUBLIC_STATUSES }) }
  scope :manageable, -> { where(status: Statusable::MANAGEABLE_STATUSES) }

  counter_culture :service,
                  column_name: proc { |model| model.published? ? "offers_count" : nil },
                  column_names: {
                    ["offers.status = ?", "published"] => "offers_count"
                  }

  belongs_to :service
  belongs_to :primary_oms, class_name: "OMS", optional: true
  has_many :project_items, dependent: :restrict_with_error

  before_validation :set_internal
  before_validation :set_oms_details
  before_validation :sanitize_oms_params
  before_validation :set_iid
  after_initialize :set_iid

  has_many :bundle_offers
  has_many :bundles, through: :bundle_offers, dependent: :destroy
  has_many :main_bundles, class_name: "Bundle", foreign_key: "main_offer_id", dependent: :restrict_with_error
  has_many :offer_vocabularies
  belongs_to :offer_category, class_name: "Vocabulary::ServiceCategory"
  belongs_to :offer_type, class_name: "Vocabulary::ServiceCategory", optional: true
  belongs_to :offer_subtype, class_name: "Vocabulary::ServiceCategory", optional: true

  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :order_url, mp_url: true, if: :order_url?

  validate :primary_oms_exists?, if: -> { primary_oms_id.present? }
  validate :check_main_bundles, if: -> { draft? }

  with_options unless: :draft? do
    validate :proper_oms?, if: -> { primary_oms.present? }
    validates :oms_params, absence: true, if: -> { current_oms.blank? }
    validate :check_oms_params, if: -> { current_oms.present? }
    validate :same_order_type_as_in_service, if: -> { service&.order_type.present? }
  end

  before_destroy :check_main_bundles

  def current_oms
    primary_oms || OMS.find_by(default: true)
  end

  def to_param
    iid.to_s
  end

  def bundle?
    main_bundles.published.size.positive?
  end

  def bundled?
    bundles.published.size.positive?
  end

  def slug_iid
    "#{service.slug}/#{iid}"
  end

  def self.find_by_slug_iid!(slug_iid)
    raise ArgumentError, "must be a string" unless slug_iid.is_a?(String)
    split = slug_iid.split("/")
    raise ArgumentError, "must have the two components separated with a forward slash '/'" if split.length != 2
    Offer.find_by!(service: Service.find_by!(slug: split[0]), iid: split[1].to_i)
  end

  private

  def set_iid
    self.iid = (service&.offers&.maximum(:iid) || 0) + 1 if iid.blank?
  end

  def duplicates?(list)
    list.uniq.size != list.size
  end

  def offers_count
    service&.offers_count || 0
  end

  def oms_params_match?
    unless (Set.new(oms_params.keys) - Set.new(current_oms.custom_params.keys)).empty?
      errors.add(:oms_params, "additional unspecified keys added")
      return false
    end

    missing_keys = Set.new(current_oms.custom_params.keys) - Set.new(oms_params.keys)
    if missing_keys.intersect?(Set.new(current_oms.mandatory_defaults.keys))
      errors.add(:oms_params, "missing mandatory keys")
    end
  end

  def same_order_type_as_in_service
    other_services = service.offers.published.reject { |o| o&.id == id }
    other_check = other_services.none? { |o| o.order_type == service&.order_type }
    if (other_services.empty? || other_check) && order_type != service.order_type
      errors.add(:order_type, "must be the same as in the service: #{service.order_type}")
    end
  end

  def check_main_bundles
    unless main_bundles.empty?
      errors.add(
        :base,
        "Offer is connected as main offer to #{pluralize(main_bundles.size, "bundle")}: " +
          "#{main_bundles.map(&:name).join(", ")}. Firstly change main offer or delete mentioned bundles"
      )
    end
  end

  def check_oms_params
    if current_oms.custom_params.present?
      if current_oms.mandatory_defaults.present?
        oms_params.blank? ? errors.add(:oms_params, "can't be blank") : oms_params_match?
      end
    elsif oms_params.present?
      errors.add(:oms_params, "must be blank if primary OMS' custom params are blank")
    end
  end

  def primary_oms_exists?
    errors.add(:primary_oms, "doesn't exist") unless OMS.find_by_id(primary_oms_id).present?
  end

  def proper_oms?
    unless service.available_omses.include? primary_oms
      errors.add(:primary_oms, "has to be available in the service scope")
    end
  end

  def set_internal
    self.internal = false unless order_required?
  end

  def set_oms_details
    unless internal?
      self.primary_oms = nil
      self.oms_params = nil
    end
  end

  def sanitize_oms_params
    oms_params.select! { |_, v| v.present? } if oms_params.present?
  end
end
