# frozen_string_literal: true

class OrderingApi::V1::EventSerializer < ActiveModel::Serializer
  attribute :timestamp
  attribute :type
  attribute :resource
  attribute :changes, if: -> { object.action_update? }
  attribute :project_id
  attribute :message_id, if: -> { object.message? }
  attribute :project_item_id, if: -> { object.message_project_item? || object.project_item? }

  def timestamp
    object.created_at.iso8601
  end

  def type
    object.action
  end

  def resource
    object.additional_info["eventable_type"].underscore
  end

  def changes
    object.updates
  end

  def project_id
    object.additional_info["project_id"]
  end

  def message_id
    object.additional_info["message_id"]
  end

  def project_item_id
    object.additional_info["project_item_id"]
  end
end
