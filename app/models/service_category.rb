# frozen_string_literal: true

class ServiceCategory < ApplicationRecord
  belongs_to :service
  belongs_to :category
  counter_culture :category,
    foreign_key_values: proc { |category_id| [category_id, *Category.find(category_id).ancestor_ids] },
    column_name: proc { |model| model.published? ? "services_count" : nil }

  validates :service, presence: true
  validates :category, presence: true

  after_save :guarantee_only_one_main, if: :main?
  after_touch :_update_counts_after_update

  attribute :status

  def published?
    status == Service.statuses[:published]
  end

  def category_id_before_last_save
    super || category_id
  end

  def saved_changes
    super.tap do |saved_changes|
      status_change = service.saved_change_to_status
      saved_changes["status"] = status_change if status_change
    end
  end

  def status
    super || (service && service.status)
  end

  private

    def guarantee_only_one_main
      ServiceCategory.where(service: service).
                      where.not(id: id).
                      update(main: false)
    end
end
