# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :eventable, polymorphic: true, optional: true

  enum action: {
    create: "create",
    update: "update",
    delete: "delete"
  }, _prefix: true

  validates :action, presence: true
  validates :additional_info, presence: true
  validate :additional_info_valid?

  validates :eventable, absence: true, if: :action_delete?

  validates :updates, presence: true, if: :action_update?
  validates :updates, absence: true, unless: :action_update?
  validate :schema_valid?, if: :action_update?

  def schema_valid?
    JSON::Validator.validate!(UPDATES_SCHEME, updates)
  rescue JSON::Schema::ValidationError => e
    errors.add(:updates, e.message)
  end

  def additional_info_valid?
    JSON::Validator.validate!(ADDITIONAL_INFO_SCHEME, additional_info)
  rescue JSON::Schema::ValidationError => e
    errors.add(:additional_info, e.message)
  end

  private
    UPDATES_SCHEME = {
      type: "array",
      items: {
        type: "object",
        minItems: 1,
        properties: {
          field: { type: "string" },
          before: { type: "string" },
          after: { type: "string" },
        },
        additionalProperties: false,
        required: [:field, :before, :after]
      }
    }

    ADDITIONAL_INFO_SCHEME = {
      type: "object",
      properties: {
        eventable_type: { type: "string", enum: %w[Project ProjectItem Message] },
        message_id: { type: "integer" },
        project_id: { type: "integer" },
        project_item_id: { type: "integer" },
      },
      additionalProperties: false,
      required: [:eventable_type, :project_id]
    }
end
