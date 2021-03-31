# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :author,
             class_name: "User",
             optional: true

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

  validates :author_role, presence: true
  validates :author, presence: true, if: :role_user?

  validates :scope, presence: true

  validates :message, presence: true
  belongs_to :messageable, polymorphic: true

  def question?
    author == messageable.user
  end
end
