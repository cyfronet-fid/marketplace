# frozen_string_literal: true

class Offer < ApplicationRecord
  # TODO: validate parameter ids uniqueness - for now we are safe thanks to schema validation though
  include Offerable
  include Offer::Parameters

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  STATUSES = { published: "published", draft: "draft", deleted: "deleted" }.freeze

  def search_data
    { offer_name: name, description: description, service_id: service_id, order_type: order_type }
  end

  def should_index?
    status == STATUSES[:published] && offers_count > 1
  end

  counter_culture :service,
                  column_name: proc { |model| model.published? ? "offers_count" : nil },
                  column_names: {
                    ["offers.status = ?", "published"] => "offers_count"
                  }

  enum status: STATUSES

  belongs_to :service
  belongs_to :primary_oms, class_name: "OMS", optional: true
  has_many :project_items, dependent: :restrict_with_error

  before_validation :set_internal
  before_validation :set_oms_details
  before_validation :sanitize_oms_params
  before_save :default_availability

  has_many :target_offer_links,
           class_name: "OfferLink",
           foreign_key: "source_id",
           inverse_of: "source",
           dependent: :destroy

  has_many :source_offer_links,
           class_name: "OfferLink",
           foreign_key: "target_id",
           inverse_of: "target",
           dependent: :destroy

  has_many :bundled_connected_offers,
           through: :target_offer_links,
           source: :target,
           dependent: :destroy,
           after_add: :bundled_offer_added
  has_many :bundle_connected_offers, through: :source_offer_links, source: :source, dependent: :destroy
  has_many :bundle_offers
  has_many :bundles, through: :bundle_offers, source: :bundle, dependent: :destroy
  has_many :main_bundles, class_name: "Bundle", foreign_key: "main_offer_id"

  validate :set_iid, on: :create
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true
  validates :order_url, mp_url: true, if: :order_url?
  validate :bundled_offers_correct, if: -> { bundled_connected_offers.present? }
  validates :available_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validate :primary_oms_exists?, if: -> { primary_oms_id.present? }
  validate :proper_oms?, if: -> { primary_oms.present? }
  validates :oms_params, absence: true, if: -> { current_oms.blank? }
  validate :check_oms_params, if: -> { current_oms.present? }
  validate :same_order_type_as_in_service,
           if: -> {
             service&.order_type.present? &&
               (
                 (new_record? && service.offers.published.size.zero?) ||
                   (persisted? && service.offers.published.size == 1)
               )
           }

  after_commit :propagate_to_ess

  def current_oms
    primary_oms || OMS.find_by(default: true)
  end

  def to_param
    iid.to_s
  end

  def offer_type
    super || service.order_type
  end

  def bundle?
    bundled_connected_offers.size.positive?
  end

  def bundled?
    bundle_connected_offers.size.positive?
  end

  def bundle_parameters?
    bundle? && (parameters.present? || bundled_connected_offers.map(&:parameters).any?(&:present?))
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

  attr_reader :added_bundled_offers

  def reset_added_bundled_offers!
    @added_bundled_offers = []
  end

  private

  def bundled_offer_added(new_bundled_offer)
    @added_bundled_offers ||= []
    @added_bundled_offers.push(new_bundled_offer)
  end

  def set_iid
    self.iid = offers_count + 1 if iid.blank?
  end

  def bundled_offers_correct
    if internal?
      errors.add(:bundled_connected_offers, "cannot bundle self") if bundled_connected_offers.include?(self)
      errors.add(:bundled_connected_offers, "cannot bundle bundle offers") if bundled_connected_offers.any?(&:bundle?)
      unless bundled_connected_offers.all?(&:published?)
        errors.add(:bundled_connected_offers, "all bundled offers must be published")
      end
      unless bundled_connected_offers.map(&:service).all?(&:public?)
        errors.add(:bundled_connected_offers, "all bundled offers' services must be public")
      end
    else
      errors.add(:bundled_connected_offers, "only internal offer can have bundled offers")
    end
  end

  def duplicates?(list)
    list.uniq.size != list.size
  end

  def offers_count
    (service && service.offers.maximum(:iid).to_i) || 0
  end

  def oms_params_match?
    unless (Set.new(oms_params.keys) - Set.new(current_oms.custom_params.keys)).empty?
      errors.add(:oms_params, "additional unspecified keys added")
      return
    end

    missing_keys = Set.new(current_oms.custom_params.keys) - Set.new(oms_params.keys)
    unless (missing_keys & Set.new(current_oms.mandatory_defaults.keys)).empty?
      errors.add(:oms_params, "missing mandatory keys")
    end
  end

  def same_order_type_as_in_service
    unless order_type == service.order_type
      errors.add(:order_type, "must be the same as in the service: #{service.order_type}")
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

  def default_availability
    self.available_count ||= 0
  end

  def sanitize_oms_params
    oms_params.select! { |_, v| v.present? } if oms_params.present?
  end

  def propagate_to_ess
    status == "published" && !destroyed? ? Offer::Ess::Add.call(self) : Offer::Ess::Delete.call(id)
  end
end
