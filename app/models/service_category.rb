# frozen_string_literal: true

class ServiceCategory < ApplicationRecord
  belongs_to :service
  belongs_to :category
  counter_culture :category,
                  column_name: "services_count",
                  foreign_key_values: ->(category_id) do
                    [category_id, *Category.find(category_id).ancestor_ids]
                  end

  validates :service, presence: true
  validates :category, presence: true

  after_save :guarantee_only_one_main

  private

    def guarantee_only_one_main
      ServiceCategory.where(service: service).
                      where.not(id: id).
                      update(main: false)
    end
end
