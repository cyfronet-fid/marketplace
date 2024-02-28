# frozen_string_literal: true

class OfferCategory < ApplicationRecord
  belongs_to :offer
  belongs_to :category

  validates :offer, presence: true, uniqueness: { scope: :offer_id }
  validates :category, presence: true
end
