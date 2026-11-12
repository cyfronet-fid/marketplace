# frozen_string_literal: true

class Event < ApplicationRecord
  UPDATES_SCHEME = {
    type: "array",
    items: {
      type: "object",
      minItems: 1,
      properties: {
        field: {
          type: "string"
        },
        before: {},
        after: {}
      },
      additionalProperties: false,
      required: %i[field before after]
    }
  }.freeze

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

  # The joins of .of_omses compare only the id of the eventable and of the messageable.
  # Each condition thus names the type, or a record of another type with the same id matches.
  OMS_CONDITIONS = [
    "events.eventable_type = 'ProjectItem' AND offers.primary_oms_id IN (:oms_ids)",
    "events.eventable_type = 'Project' AND offers_project_items.primary_oms_id IN (:oms_ids)",
    "events.eventable_type = 'Message' AND messages.messageable_type = 'ProjectItem' " \
    "AND offers_project_items_2.primary_oms_id IN (:oms_ids)",
    "events.eventable_type = 'Message' AND messages.messageable_type = 'Project' " \
    "AND offers_project_items_3.primary_oms_id IN (:oms_ids)"
  ].freeze

  # Events of ProjectItem OR Project OR Message eventables
  # with one of the OMSes inside their respective offers.primary_oms
  scope :of_omses,
        lambda { |oms_ids|
          where(OMS_CONDITIONS.map { |condition| "(#{condition})" }.join(" OR "), oms_ids: oms_ids)
            .left_outer_joins(
              { project_item: :offer },
              { project: { project_items: :offer } },
              { message: { project_item: :offer } },
              { message: { project: { project_items: :offer } } }
            )
            .distinct
        }

  validates :action, presence: true
  validates :updates, presence: true, if: :action_update?
  validates :updates, absence: true, unless: :action_update?
  validate :updates_schema?, if: :action_update?

  after_commit :call_triggers, on: :create

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
