# frozen_string_literal: true

class Guideline < ApplicationRecord
  has_many :services, through: :guidelines_services
end
