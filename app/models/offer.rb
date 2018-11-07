# frozen_string_literal: true

class Offer < ApplicationRecord
  belongs_to :service,
             counter_cache: true

  has_many :project_items,
           dependent: :restrict_with_error

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

  private

  def set_iid
    self.iid = offers_count + 1 if iid.blank?
  end

  def offers_count
    service && service.offers.maximum(:iid).to_i || 0
  end
end
