# frozen_string_literal: true

class BundleScientificDomain < ApplicationRecord
  belongs_to :bundle
  belongs_to :scientific_domain

  validates :bundle, presence: true
  validates :scientific_domain, presence: true
end
