# frozen_string_literal: true

class UserResearchArea < ApplicationRecord
  belongs_to :user
  belongs_to :research_area

  validates :user, presence: true
  validates :research_area, presence: true, uniqueness: { scope: :user_id }
end
