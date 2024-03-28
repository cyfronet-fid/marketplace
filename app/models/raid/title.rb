# frozen_string_literal: true

class Raid::Title < ::ApplicationRecord
  extend ActiveModel::Naming
  belongs_to :raid_project
  belongs_to :raid_project
  enum title_type: { primary: "primary", alternative: "alternative" }

  validates :text, presence: true, length: { minimum: 1, maximum: 100 }
  validates :title_type, presence: true
  validates :type, presence: true
  validates :start_date, presence: true
  validates :language, length: { minimum: 3, maximum: 3 }
  validate :validate_dates
  validate :start_date, :title_valid

  def validate_dates
    if end_date && !validate_start_end_date(start_date, end_date)
      errors.add(:end_date, "End date cannot precede start date")
    end
  end

  def title_valid
    errors.add(:start_date, "The date must fall within projects dates") unless validate_title_date(start_date)
    if end_date.present? && !validate_title_date(end_date)
      errors.add(:end_date, "The date must fall within projects dates")
    end
  end

  # validate start date is earlier than end date
  def validate_start_end_date(start_date, end_date)
    start_date < end_date
  end

  #validate title start / end dates falls within project dates
  def validate_title_date(date)
    return date >= raid_project.start_date && date <= raid_project.end_date if raid_project.end_date
    date >= raid_project.start_date
  end
end
