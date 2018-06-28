# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    ready: "ready",
    rejected: "rejected"
  }

  ISSUE_STATUSES = {
      jira_active: 0,
      jira_deleted: 1,
      jira_uninitialized: 2,
      jira_errored: 3
  }

  enum status: STATUSES
  enum issue_status: ISSUE_STATUSES

  belongs_to :service
  belongs_to :user
  has_many :order_changes, dependent: :destroy

  validates :service, presence: true
  validates :user, presence: true
  validates :status, presence: true

  def active?
    !(ready? || rejected?)
  end

  def new_change(status: nil, message: nil, author: nil)
    # don't create change when there is not status and message given
    return unless status || message

    status ||= self.status

    order_changes.create(status: status, message: message, author: author).tap do
      update_attributes(status: status)
    end
  end

  def to_s
    "##{id}"
  end
end
