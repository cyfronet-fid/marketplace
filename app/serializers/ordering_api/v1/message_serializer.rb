# frozen_string_literal: true

class OrderingApi::V1::MessageSerializer < ActiveModel::Serializer
  attribute :id
  attribute :author
  attribute :message, key: :content
  attribute :message_scope, key: :scope
  attributes :created_at, :updated_at

  def author
    {
      email: object.role_user? ? object.author.email : object.author_email,
      name: object.role_user? ? object.author.full_name : object.author_name,
      role: object.author_role
    }
  end

  def message_scope
    # scope is a reserved keyword in ActiveModel::Serializer
    object.scope
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
