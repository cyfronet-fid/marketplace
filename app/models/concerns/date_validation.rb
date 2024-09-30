# frozen_string_literal: true

module DateValidation
  extend ActiveSupport::Concern

  included do
    validates :start_date, presence: true
    validate :validate_dates
    validate :start_date, :item_valid, if: -> { start_date.present? }
    validate :end_date, :item_valid, if: -> { start_date.present? }
  end

  def validate_dates
    if end_date.present? && !validate_start_end_date(start_date, end_date)
      errors.add(:end_date, " cannot precede start date")
    end
  end

  def item_valid
    errors.add(:start_date, "must fall within projects dates") unless validate_item_date(start_date)
    errors.add(:end_date, "must fall within projects dates") if end_date.present? && !validate_item_date(end_date)
  end

  # validate start date is earlier than end date
  def validate_start_end_date(start_date, end_date)
    start_date < end_date
  end

  #validate start / end dates falls within project dates
  def validate_item_date(date)
    if instance_of?(Raid::Position)
      start_date = positionable.raid_project.start_date
      end_date = positionable.raid_project.end_date
    else
      start_date = raid_project.start_date
      end_date = raid_project.end_date
    end
    return date >= start_date && date <= end_date if end_date
    date >= start_date
  end
end
