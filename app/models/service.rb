# frozen_string_literal: true

require "elasticsearch/model"

class Service < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  has_many :service_categories, dependent: :destroy
  has_many :categories, through: :service_categories

  validates :title, presence: true
  validates :description, presence: true

  after_save :set_main_category, if: :main_category_missing?

  def main_category
    @main_category ||= categories.joins(:service_categories).
                                  find_by(service_categories: { main: true })
  end

  private

    def main_category_missing?
      service_categories.where(main: true).count.zero?
    end

    def set_main_category
      service_categories.first&.update_attributes(main: true)
    end
end
