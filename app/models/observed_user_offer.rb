# frozen_string_literal: true

class ObservedUserOffer < ApplicationRecord
  belongs_to :user
  belongs_to :offer

  validates :user, presence: true, uniqueness: { scope: :offer_id }
  validates :offer, presence: true
end
