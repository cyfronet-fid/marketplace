# frozen_string_literal: true

class Raid::Description < ApplicationRecord
  belongs_to :raid_project

  enum description_type: { primary: "primary", alternative: "alternative" }

  validates :text, presence: true, length: { minimum: 1, maximum: 1000 }
  validates :description_type, presence: true
  validates :type, presence: true
  validates :language, length: { minimum: 3, maximum: 3 }
end
