# frozen_string_literal: true

class Message < ApplicationRecord
  include Eventable

  enum author_role: {
    user: "user",
    provider: "provider",
    mediator: "mediator",
  }, _prefix: :role

  enum scope: {
    public: "public",
    internal: "internal",
    user_direct: "user_direct",
  }, _suffix: true

  belongs_to :author,
             class_name: "User",
             optional: true
  belongs_to :messageable, polymorphic: true

  validates :author_role, presence: true
  validates :author, presence: true, if: :role_user?

  validates :scope, presence: true

  validates :message, presence: true

  def question?
    author == messageable.user
  end

  def eventable_identity
    messageable.eventable_identity.merge({ message_id: id })
  end
end
