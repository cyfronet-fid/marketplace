# frozen_string_literal: true

class Category < ApplicationRecord
  has_ancestry

  validates :name, presence: true
end
