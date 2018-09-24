# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :services, dependent: :nullify

  validates :name, presence: true
end
