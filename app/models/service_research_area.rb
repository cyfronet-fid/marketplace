# frozen_string_literal: true

class ServiceResearchArea < ApplicationRecord
  belongs_to :service
  belongs_to :research_area

  validates :service, presence: true
  validates :research_area, presence: true, uniqueness: { scope: :service_id }
end
