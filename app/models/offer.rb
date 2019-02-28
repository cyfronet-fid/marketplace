# frozen_string_literal: true

class Offer < ApplicationRecord
  enum offer_type: {
    normal: "normal",
    open_access: "open_access",
    catalog: "catalog"
  }

  belongs_to :service,
             counter_cache: true

  has_many :project_items,
           dependent: :restrict_with_error

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

  has_many :bundled_offers,
           through: :target_offer_links,
           source: :target

  validate :set_iid, on: :create
  validates :name, presence: true
  validates :description, presence: true
  validates :service, presence: true
  validates :iid, presence: true, numericality: true

  def to_param
    iid.to_s
  end

  def attributes
    (parameters || []).map { |param| Attribute.from_json(param) }
  end

  def offer_type
    super || service.service_type
  end

  def open_access?
    offer_type == "open_access"
  end

  def normal?
    offer_type == "normal"
  end

  def catalog?
    offer_type == "catalog"
  end

  def bundle?
    bundled_offers_count.positive?
  end

  private

    def set_iid
      self.iid = offers_count + 1 if iid.blank?
    end

    def offers_count
      service && service.offers.maximum(:iid).to_i || 0
    end
end
