# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true
  belongs_to :project,
             -> { where(events: { eventable_type: "Project" }).includes(:events) },
             foreign_key: "eventable_id",
             optional: true
  belongs_to :project_item,
             -> { where(events: { eventable_type: "ProjectItem" }).includes(:events) },
             foreign_key: "eventable_id",
             optional: true
  belongs_to :message,
             -> { where(events: { eventable_type: "Message" }).includes(:events) },
             foreign_key: "eventable_id",
             optional: true

  enum :action, { create: "create", update: "update" }, prefix: true

  validates :action, presence: true
  validates :updates, presence: true, if: :action_update?
  validates :updates, absence: true, unless: :action_update?
  validate :updates_schema?, if: :action_update?

  after_commit :call_triggers, on: :create

  UPDATES_SCHEME = {
    type: "array",
    items: {
      type: "object",
      minItems: 1,
      properties: {
        field: {
          type: "string"
        },
        before: {
        },
        after: {
        }
      },
      additionalProperties: false,
      required: %i[field before after]
    }
  }.freeze

  def omses
    default = OMS.find_by(default: true)
    other = eventable.eventable_omses
    default.blank? || other.any? { |oms| oms.id == default.id } ? other : other.push(default)
  end

  private

  def updates_schema?
    JSON::Validator.validate!(UPDATES_SCHEME, updates)
  rescue JSON::Schema::ValidationError => e
    errors.add(:updates, e.message)
  end

  def call_triggers
    Event::CallTriggers.new(self).call
  end
end
