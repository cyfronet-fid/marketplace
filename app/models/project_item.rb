# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    ready: "ready",
    rejected: "rejected",
    deactivated: "deactivated"
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
  belongs_to :project
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :project_item_changes, dependent: :destroy

  validates :service, presence: true
  validates :project, presence: true
  validates :status, presence: true

  delegate :user, to: :project

  def draft?
    !(ready? || rejected? || deactivated?)
  end

  def new_change(status: nil, message: nil, author: nil, iid: nil)
    # don't create change when there is not status and message given
    return unless status || message

    status ||= self.status

    project_item_changes.create(status: status, message: message, author: author, iid: iid).tap do
      update_attributes(status: status)
    end
  end

  def to_s
    "##{id}"
  end
end
