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

  has_many :bundled_offers, through: :target_offer_links, source: :target

  validate :set_iid, on: :create
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true
  validates :order_url, mp_url: true, if: :order_url?

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

  def current_oms
    primary_oms || OMS.find_by(default: true)
  end

  def to_param
    iid.to_s
  end

  def offer_type
    super || service.service_type
  end

  def bundle?
    bundled_offers_count.positive?
  end

  def bundle_parameters?
    bundle? && (parameters.present? || bundled_offers.map(&:parameters).any?(&:present?))
  end

  private

  def set_iid
    self.iid = offers_count + 1 if iid.blank?
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
      errors.add(:order_type, "must be the same as in the resource: #{service.order_type}")
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
      errors.add(:primary_oms, "has to be available in the resource scope")
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
