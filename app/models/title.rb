class Title < ApplicationRecord
  belongs_to :raid_project
  belongs_to :raid_project
  enum title_type: { primary: "primary", alternative: "alternative" }

  validates :text, presence: true, length: { minimum: 1, maximum: 100 }
  validates :title_type, presence: true 
  validates :type, presence: true 
  validates :start_date, presence: true
  validate :validate_dates
  validate :start_date, :title_valid

  def validate_dates
      if self.end_date && !validate_start_end_date(self.start_date, self.end_date)
          errors.add(:end_date, "End date cannot precede start date")
      end
  end

  def title_valid
    if !validate_title_date(start_date)
        errors.add(:start_date, "The date must fall within projects dates")
    end
    if end_date.present? 
        if !validate_title_date(end_date)
            errors.add(:end_date, "The date must fall within projects dates")
        end
    end
  end

  # validate start date is earlier than end date
  def validate_start_end_date(start_date, end_date)
    return start_date < end_date 
  end

  #validate title start / end dates falls within project dates
  def validate_title_date(date)
    if raid_project.end_date
        return date >= raid_project.start_date && date <= raid_project.end_date
    end
    return date >= raid_project.start_date 
  end
end
