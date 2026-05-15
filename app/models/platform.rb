# frozen_string_literal: true

class Platform < ApplicationRecord
  include Publishable

  include Parentable

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
