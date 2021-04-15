# frozen_string_literal: true

class OrderingApi::V1::EventSerializer < ActiveModel::Serializer
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
      if update["field"] == "user_secrets"
        update["after"] = "<OBFUSCATED>"
        update["before"] = "<OBFUSCATED>"
      end
      update
    end
  end

  [:project_id, :project_item_id, :message_id].each do |identity_part|
    define_method identity_part do
      object.eventable.eventable_identity[identity_part]
    end
  end
end
