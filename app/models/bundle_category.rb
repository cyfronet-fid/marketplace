# frozen_string_literal: true

class BundleCategory < ApplicationRecord
  belongs_to :bundle
  belongs_to :category

  validates :bundle, presence: true
  validates :category, presence: true
end
