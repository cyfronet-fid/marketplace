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
        unless self.previous_changes.blank?
          updates = self.previous_changes.map { |attr, change| { field: attr, before: change[0], after: change[1] }  }
          updates = updates.filter { |update| update[:field] != "updated_at" }
          Event.create!(action: :update, eventable: self, updates: updates)
        end
      end
  end
end
