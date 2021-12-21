# frozen_string_literal: true

class Api::V1::EventSerializer < ActiveModel::Serializer
  attribute :timestamp
  attribute :type
  attribute :resource
  attribute :changes, if: -> { object.action_update? }
  attribute :project_id
  attribute :project_item_id, if: :project_item_id
  attribute :message_id, if: :message_id

  def timestamp
    object.created_at.iso8601
  end

  def type
    object.action
  end

  def resource
    object.eventable_type.underscore
  end

  def changes
    object.updates&.map do |update|
      if should_obfuscate?(update["field"])
        update["after"] = "<OBFUSCATED>"
        update["before"] = "<OBFUSCATED>"
      end
      update["field"] = transform_to_api_field(update["field"])
      update
    end
  end

  %i[project_id project_item_id message_id].each do |identity_part|
    define_method identity_part do
      object.eventable.eventable_identity[identity_part]
    end
  end

  private

  def transform_to_api_field(field)
    mappings = {
      "Message" => {
        "message" => "content"
      },
      "ProjectItem" => {
        "status" => "status.value",
        "status_type" => "status.type"
      }
    }
    mappings.fetch(object.eventable_type, {}).fetch(field, field)
  end

  def should_obfuscate?(field)
    case object.eventable_type
    when "Message"
      field == "message" && object.eventable.user_direct_scope?
    when "ProjectItem"
      field == "user_secrets"
    else
      false
    end
  end
end
