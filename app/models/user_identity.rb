# frozen_string_literal: true

class UserIdentity < ApplicationRecord
  belongs_to :user, inverse_of: :identities

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { conditions: -> { where(primary: true) } }, if: :primary?

  scope :primary, -> { where(primary: true) }
end
