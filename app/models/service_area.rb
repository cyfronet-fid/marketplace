# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  belongs_to :service
  belongs_to :area

  validates :service, presence: true
  validates :area, presence: true
end
