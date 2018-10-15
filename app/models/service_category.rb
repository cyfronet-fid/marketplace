# frozen_string_literal: true

class ServiceCategory < ApplicationRecord
  belongs_to :service
  belongs_to :category, counter_cache: :services_count

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
