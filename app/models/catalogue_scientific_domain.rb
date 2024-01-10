# frozen_string_literal: true

class CatalogueScientificDomain < ApplicationRecord
  belongs_to :catalogue
  belongs_to :scientific_domain
end
