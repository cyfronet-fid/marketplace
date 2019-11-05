# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  include Customization
  include ProjectValidation
  include VoucherValidation
  include Iid

  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    waiting_for_response: "waiting_for_response",
    ready: "ready",
    rejected: "rejected",
    closed: "closed",
    approved: "approved"
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
  belongs_to :research_area, required: false
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :messages, as: :messageable, dependent: :destroy
  has_many :statuses, as: :status_holder

  validates :offer, presence: true
  validates :status, presence: true
  validate :research_area_is_a_leaf
  validate :properties_not_nil

  delegate :user, to: :project
  delegate :orderable?, to: :offer, allow_nil: true

  def service
    offer.service unless offer.nil?
  end

  def active?
    !(ready? || rejected?)
  end

  def new_status(status: nil, message: nil, author: nil)
    # don't create change when there is not status and message given
    return unless status || message

    status ||= self.status

    statuses.create(status: status, message: message, author: author).tap do
      update_attributes(status: status)
    end
  end

  def new_voucher_change(voucher_id, author: nil, iid: nil)
    voucher_id ||= ""

    return unless voucher_id != self.voucher_id

    message = if self.voucher_id.blank? && !voucher_id.blank?
      "Voucher has been granted to you, ID: #{voucher_id}"
    elsif !self.voucher_id.blank? && voucher_id.blank?
      "Voucher has been revoked"
    elsif !self.voucher_id.blank? && !voucher_id.blank?
      "Voucher ID has been updated: #{voucher_id}"
    end

    messages.create(message: message, author: author, iid: iid).tap do
      update_attributes(voucher_id: voucher_id)
    end
  end

  def to_s
    "\"#{project.name}##{id}\""
  end

  def research_area_is_a_leaf
    errors.add(:research_area_id, "cannot have children") if research_area&.has_children?
  end

  def properties_not_nil
    if self.properties.nil?
      errors.add :properties, "cannot be nil"
    end
  end
end
