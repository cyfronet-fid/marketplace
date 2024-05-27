# frozen_string_literal: true

class Raid::Title < ApplicationRecord
  extend ActiveModel::Naming
  include DateValidation
  belongs_to :raid_project
  enum title_type: { primary: "primary", alternative: "alternative" }

  validates :text, presence: true, length: { minimum: 1, maximum: 100 }
  validates :title_type, presence: true
  validates :type, presence: true
  validates :language, length: { minimum: 3, maximum: 3 }
end
