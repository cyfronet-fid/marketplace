# frozen_string_literal: true

class Api::V1::MessageSerializer < ActiveModel::Serializer
  attribute :id
  attribute :author
  attribute :filtered_content, key: :content
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

  def filtered_content
    if object.user_direct_scope? && !instance_options[:keep_content?]
      "<OBFUSCATED>"
    else
      object.message
    end
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
