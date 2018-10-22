# frozen_string_literal: true

class Category < ApplicationRecord
  has_ancestry

  # This callback need to be defined byfore dependent: :destroy
  # relation, because in this case project_item matter. This callback need to be
  # invoked before destroying related service categories to find affected
  # services.
  before_destroy :store_affected_services

  has_many :service_categories, autosave: true, dependent: :destroy
  has_many :services, through: :service_categories

  validates :name, presence: true

  after_destroy :update_main_categories!

  private

    def store_affected_services
      # neet do store results in array since relation is lazy evaluated
      @main_services = Service.joins(:service_categories).
        where(service_categories: { category: self, main: true }).to_a
    end

    def update_main_categories!
      @main_services.each { |s| s.set_first_category_as_main! }
    end
end
