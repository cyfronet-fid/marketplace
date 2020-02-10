# frozen_string_literal: true

class HomePage < ApplicationRecord
  validates :sections, presence: true
end
