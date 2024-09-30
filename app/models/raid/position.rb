# frozen_string_literal: true

class Raid::Position < ApplicationRecord
  belongs_to :positionable, polymorphic: true, inverse_of: :positionable
  include DateValidation

  validates :pid, presence: true
end
