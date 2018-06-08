# frozen_string_literal: true

class Category < ApplicationRecord
  has_ancestry

  has_many :service_categories, autosave: true, dependent: :destroy
  has_many :services, through: :service_categories

  validates :name, presence: true
end
