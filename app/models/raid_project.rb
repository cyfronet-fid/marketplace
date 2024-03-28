# frozen_string_literal: true

class RaidProject < ApplicationRecord
  has_one :main_title, class_name: "Raid::MainTitle", dependent: :destroy, autosave: true, inverse_of: :raid_project
  has_many :alternative_titles,
           class_name: "Raid::AlternativeTitle",
           dependent: :destroy,
           autosave: true,
           inverse_of: :raid_project
  belongs_to :user

  accepts_nested_attributes_for :main_title, allow_destroy: true
  validates_associated :main_title
  accepts_nested_attributes_for :alternative_titles, allow_destroy: true

  validates :main_title, presence: true
  validates :start_date, presence: true

  validate :validate_dates

  def validate_dates
    if end_date && !validate_start_end_date(start_date, end_date)
      errors.add(:end_date, "End date cannot precede start date")
    end
  end

  def validate_start_end_date(start_date, end_date)
    start_date < end_date
  end
end
