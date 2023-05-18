# frozen_string_literal: true

class Guideline < ApplicationRecord
  has_many :service_guidelines, dependent: :destroy
  has_many :services, through: :service_guidelines
end
