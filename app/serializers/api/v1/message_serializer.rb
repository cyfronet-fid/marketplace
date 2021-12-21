# frozen_string_literal: true

class Api::V1::MessageSerializer < ActiveModel::Serializer
  attribute :id
  attribute :author
  attribute :filtered_content, key: :content
  attribute :message_scope, key: :scope
  attributes :created_at, :updated_at

  def author
    if object.role_user?
      { uid: object.author&.uid, email: object.author&.email, name: object.author&.full_name }
    else
      { uid: object.author_uid, email: object.author_email, name: object.author_name }
    end.merge({ role: object.author_role }).select { |_, value| value.present? }
  end

  def message_scope
    # scope is a reserved keyword in ActiveModel::Serializer
    object.scope
  end

  def filtered_content
    object.user_direct_scope? && !instance_options[:keep_content?] ? "<OBFUSCATED>" : object.message
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
