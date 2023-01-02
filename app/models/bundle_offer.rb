# frozen_string_literal: true

class BundleOffer < ApplicationRecord
  belongs_to :bundle
  belongs_to :offer

  validates :bundle, presence: true
  validates :offer, presence: true
end
