# frozen_string_literal: true

class Platform < ApplicationRecord
  has_many :service_related_platforms, dependent: :destroy
  has_many :services, through: :service_related_platforms

  validates :name, presence: true
end
