# frozen_string_literal: true

class Offer < ApplicationRecord
  belongs_to :service

  validates :title, presence: true
  validates :description, presence: true
end
