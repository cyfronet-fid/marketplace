# frozen_string_literal: true

class Message < ApplicationRecord
  include Eventable

  # TODO: probably we should change mediator to coordinator
  enum :author_role, { user: "user", provider: "provider", mediator: "mediator" }, prefix: :role

  enum :scope, { public: "public", internal: "internal", user_direct: "user_direct" }, suffix: true

  belongs_to :author, class_name: "User", optional: true
  belongs_to :messageable, polymorphic: true
  belongs_to :project_item,
             -> { where(messages: { messageable_type: "ProjectItem" }).includes(:messages) },
             foreign_key: "messageable_id",
             optional: true
  belongs_to :project,
             -> { where(messages: { messageable_type: "Project" }).includes(:messages) },
             foreign_key: "messageable_id",
             optional: true
  belongs_to :approval_request,
             -> { where(messages: { messageable_type: "ApprovalRequest" }).includes(:messages) },
             foreign_key: "messageable_id",
             optional: true

  validates :author_role, presence: true
  validates :author, presence: true, if: :role_user?

  validates :scope, presence: true

  validates :message, presence: true

  before_update :set_edited!

  after_commit :dispatch_create_email, on: :create, if: :dispatch_email?
  after_commit :dispatch_update_email, on: :update, if: %i[dispatch_email? message_previously_changed?]

  def question?
    author == messageable.user
  end

  def eventable_identity
    messageable.eventable_identity.merge({ message_id: id })
  end

  def eventable_attributes
    Set.new(%i[message])
  end

  def eventable_omses
    messageable.eventable_omses
  end

  private

  def set_edited!
    self.edited = true
  end

  def dispatch_email?
    !role_user? && !internal_scope?
  end

  def dispatch_create_email
    action = approval_request.present? ? approval_request.last_action : nil
    MessageMailer.new_message(self, action: action).deliver_later
  end

  def dispatch_update_email
    MessageMailer.message_edited(self).deliver_later
  end
end
