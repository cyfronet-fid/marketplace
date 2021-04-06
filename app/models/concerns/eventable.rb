# frozen_string_literal: true

module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :nullify

    after_create :event_on_create
    before_update :event_on_update
    before_destroy :event_on_destroy

    private
      def additional_info
        if self.class.name == "Project"
          {
            eventable_type: "Project",
            project_id: self.id
          }
        elsif self.class.name == "ProjectItem"
          {
            eventable_type: "ProjectItem",
            project_id: self.project.id,
            project_item_id: self.iid,
          }
        elsif self.class.name == "Message"
          if self.messageable.class.name == "Project"
            {
              eventable_type: "Message",
              message_id: self.id,
              project_id: self.messageable.id
            }
          elsif self.messageable.class.name == "ProjectItem"
            {
              eventable_type: "Message",
              message_id: self.id,
              project_id: self.messageable.project.id,
              project_item_id: self.messageable.iid
            }
          end
        end
      end

      def event_on_create
        Event.create(action: :create, eventable: self, additional_info: additional_info)
      end

      def event_on_update
        updates = self.changes.map { |attr, change| { field: attr, before: change[0], after: change[1] }  }
        updates = updates.filter { |update| update[:field] != "updated_at" }
        Event.create(action: :update, eventable: self, updates: updates, additional_info: additional_info)
      end

      def event_on_destroy
        Event.create(action: :delete, additional_info: additional_info)
      end
  end
end
