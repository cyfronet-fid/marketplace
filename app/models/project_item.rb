# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  include Customization
  include ProjectValidation
  include VoucherValidation
  include Iid
  include Offerable

  STATUS_TYPES = {
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

  enum status_type: STATUS_TYPES
  enum issue_status: ISSUE_STATUSES

  belongs_to :offer
  belongs_to :service, inverse_of: :project_items
  belongs_to :project
  belongs_to :scientific_domain, required: false
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :messages, as: :messageable, dependent: :destroy
  has_many :statuses, as: :status_holder
  counter_culture [:offer, :service], column_name: "project_items_count"

  validates :offer, presence: true
  validates :status, presence: true
  validates :status_type, presence: true
  validate :scientific_domain_is_a_leaf
  validate :properties_not_nil
  validate :user_secrets_is_simple

  delegate :user, to: :project

  before_validation :copy_offer_fields, on: :create

  def service
    offer.service unless offer.nil?
  end

  def public_statuses
    statuses.where.not(status: "registered")
  end

  def active?
    !(ready? || rejected?)
  end

  def new_status(status:, status_type:, author: nil)
    statuses.create(status: status, status_type: status_type, author: author).tap do
      update(status: status, status_type: status_type)
    end
  end

  def new_voucher_change(voucher_id, author: nil, iid: nil)
    voucher_id ||= ""

    return if voucher_id == user_secrets["voucher_id"]

    message = if user_secrets["voucher_id"].blank? && voucher_id.present?
      "Voucher has been granted to you, ID: #{voucher_id}"
    elsif user_secrets["voucher_id"].present? && voucher_id.blank?
      "Voucher has been revoked"
    elsif user_secrets["voucher_id"].present? && voucher_id.present?
      "Voucher ID has been updated: #{voucher_id}"
    end

    messages.create(
      message: message,
      author: author,
      author_role: :provider,
      scope: :user_direct,
      iid: iid
    ).tap do
      update(user_secrets: user_secrets.merge("voucher_id" => voucher_id))
    end
  end

  def to_s
    "\"#{project.name}##{id}\""
  end

  private
    def scientific_domain_is_a_leaf
      errors.add(:scientific_domain_id, "cannot have children") if scientific_domain&.has_children?
    end

    def properties_not_nil
      if self.properties.nil?
        errors.add :properties, "cannot be nil"
      end
    end

    def user_secrets_is_simple
      unless self.user_secrets&.values.all? { |v| v.is_a? String }
        errors.add(:user_secrets, "values must be strings")
      end
    end

    def copy_offer_fields
      self.order_type = offer&.order_type
      self.name = offer&.name
      self.description = offer&.description
      self.webpage = offer&.webpage
      self.voucherable = offer&.voucherable
      self.order_url = offer&.order_url
      self.internal = offer&.internal
    end
end
