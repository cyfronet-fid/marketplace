# frozen_string_literal: true

class Raid::RaidAccess < ApplicationRecord
  belongs_to :raid_project

  enum access_type: { open: "open", embargoed: "embargoed" }

  validates :access_type, presence: true
  validates :statement_text, presence: true, unless: :open?
  validates :statement_lang, length: { minimum: 3, maximum: 3 }, if: :statement_text?
  validates :embargo_expiry, presence: true, unless: :open?
  validate :validate_embargo_expiry, unless: :open?

  def validate_embargo_expiry
    return if embargo_expiry.blank?
    created_date = DateTime.current.to_date
    created_date = created_at if id.present?
    valid = ((embargo_expiry > created_date) && (embargo_expiry <= created_date + 18.month)) || false
    unless valid
      errors.add(:embargo_expiry, "Embargo expiry date have to be no greater than 18 months from the RAID creation")
    end
  end
end
