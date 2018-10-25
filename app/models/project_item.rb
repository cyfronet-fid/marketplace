# frozen_string_literal: true

class ProjectItem < ApplicationRecord
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

  belongs_to :offer
  belongs_to :project
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :project_item_changes, dependent: :destroy

  validates :offer, presence: true
  validates :project, presence: true
  validates :status, presence: true
  validates_associated :property_values

  delegate :user, to: :project
  delegate :service, to: :offer

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

  attribute :property_values

  def property_values
    if !@property_values
      @property_values = offer.attributes.dup
    end
    @property_values
  end

  def property_values=(property_values)
    if property_values.is_a?(Array)
      @property_values = property_values
    elsif property_values.is_a?(Hash)
      props= []
      property_values.each{ |id, value|
        attr = offer.attributes.find { |attr|
          id == attr.id
        }.dup
        attr.value_from_param(value)
        props << attr
      }
      @property_values = props
    end
    self.write_attribute(:property_values, @property_values)
    @property_values
  end

end
