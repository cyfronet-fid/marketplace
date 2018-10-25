# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    ready: "ready",
    rejected: "rejected"
  }

  CUSTOMER_TYPOLOGIES = {
    "Single user": 0,
    "Representing a research community/project": 1,
    "Representing a private company": 2
  }

  ISSUE_STATUSES = {
      jira_active: 0,
      jira_deleted: 1,
      jira_uninitialized: 2,
      jira_errored: 3
  }

  enum status: STATUSES
  enum issue_status: ISSUE_STATUSES
  enum customer_typologies: CUSTOMER_TYPOLOGIES

  belongs_to :offer
  belongs_to :project
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :project_item_changes, dependent: :destroy

  validates :offer, presence: true
  validates :project, presence: true
  validates :status, presence: true
  validates :customer_typology, presence: true, unless: :open_access?
  validates :access_reason, presence: true, unless: :open_access?
  validates :additional_information, presence: true, unless: :open_access?

  delegate :user, to: :project
  delegate :service, to: :offer

  def open_access?
    offer&.service&.open_access
  end

  def active?
    !(ready? || rejected?)
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
