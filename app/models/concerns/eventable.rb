# frozen_string_literal: true

module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy

    after_commit :event_on_create, on: :create
    after_commit :event_on_update, on: :update

    private

    def event_on_create
      Event.create!(action: :create, eventable: self)
    end

    def event_on_update
      Event.create!(action: :update, eventable: self, updates: filtered_updates) if filtered_updates.present?
    end

    def filtered_updates
      return [] if previous_changes.blank?
      previous_changes.filter_map do |attr, change|
        { field: attr, before: change[0], after: change[1] } if eventable_attributes.include? attr.to_sym
      end
    end
  end
end
