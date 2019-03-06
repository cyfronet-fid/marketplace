# frozen_string_literal: true

class Offer < ApplicationRecord
  enum offer_type: {
    normal: "normal",
    open_access: "open_access",
    catalog: "catalog"
  }

  STATUSES = {
    published: "published",
    draft: "draft"
  }

  enum status: STATUSES

  belongs_to :service

  has_many :project_items,
           dependent: :restrict_with_error

  counter_culture :service, column_name: proc { |model| model.published? ? "offers_count" : nil }

  validate :set_iid, on: :create
  validates :name, presence: true
  validates :description, presence: true
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true

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

  private

    def set_iid
      self.iid = offers_count + 1 if iid.blank?
    end

    def offers_count
      service && service.offers.maximum(:iid).to_i || 0
    end
end
