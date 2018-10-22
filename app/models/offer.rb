# frozen_string_literal: true

class Offer < ApplicationRecord
  belongs_to :service

  has_many :project_items, dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :title, presence: true
  validates :description, presence: true
  validates :service, presence: true
  validates :iid, presence: true, numericality: true

  def to_param
    iid.to_s
  end

  private

    def set_iid
      self.iid = service.offers.maximum(:iid).to_i + 1 if iid.blank?
    end
end
