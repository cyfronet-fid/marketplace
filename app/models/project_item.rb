# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  include Customizations
  include Eventable
  include Messageable
  include Customization
  include VoucherValidation
  include Iid
  include Offerable
  include Parentable

  STATUS_TYPES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    waiting_for_response: "waiting_for_response",
    ready: "ready",
    rejected: "rejected",
    closed: "closed",
    approved: "approved"
  }.freeze

  ISSUE_STATUSES = { jira_active: 0, jira_deleted: 1, jira_uninitialized: 2, jira_errored: 3 }.freeze

  enum :status_type, STATUS_TYPES
  enum :issue_status, ISSUE_STATUSES

  attr_accessor :additional_comment

  belongs_to :offer
  belongs_to :bundle, optional: true
  belongs_to :service, inverse_of: :project_items
  belongs_to :project
  belongs_to :scientific_domain, required: false
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :statuses, as: :status_holder

  counter_culture %i[offer service], column_name: "project_items_count"
  counter_culture :offer, column_name: "project_items_count"
  counter_culture :bundle, column_name: "project_items_count"
  counter_culture :offer,
                  column_name: proc { |model| model.offer.limited_availability ? "availability_count" : nil },
                  delta_magnitude: -1

  validates :offer, presence: true
  validates :status, presence: true
  validates :status_type, presence: true
  validates :project, presence: true
  validate :scientific_domain_is_a_leaf
  validate :properties_not_nil
  validate :user_secrets_is_simple

  delegate :user, to: :project

  before_validation :copy_offer_fields, on: :create

  after_save :create_new_status, if: :saved_status_change?
  after_save :voucher_id_changes!
  after_save :create_voucher_id_message, if: :saved_voucher_id_change?

  after_commit :dispatch_emails

  def service
    offer&.service || bundle&.service
  end

  def public_statuses
    statuses.where.not(status: "registered")
  end

  def active?
    !(ready? || rejected?)
  end

  def bundle?
    bundle.present?
  end

  def new_status(status:, status_type:)
    update(status: status, status_type: status_type)
  end

  def new_status!(status:, status_type:)
    update!(status: status, status_type: status_type)
  end

  def new_voucher_change(voucher_id)
    update(user_secrets: user_secrets.merge("voucher_id" => voucher_id))
  end

  def eventable_identity
    { project_id: project.id, project_item_id: iid }
  end

  def eventable_attributes
    Set.new(%i[status status_type user_secrets])
  end

  def eventable_omses
    offer.primary_oms.present? ? [offer.primary_oms] : []
  end

  def to_s
    project.present? ? "\"#{project&.name}##{id}\"" : "\"new\""
  end

  private

  def scientific_domain_is_a_leaf
    errors.add(:scientific_domain_id, "cannot have children") if scientific_domain&.has_children?
  end

  def properties_not_nil
    errors.add :properties, "cannot be nil" if properties.nil?
  end

  def user_secrets_is_simple
    errors.add(:user_secrets, "values must be strings") unless user_secrets&.values&.all? { |v| v.is_a? String }
  end

  def copy_offer_fields
    current = offer || bundle&.main_offer
    self.order_type = current&.order_type
    self.name = current&.name
    self.description = current&.description
    self.voucherable = bundle&.all_offers&.any?(&:voucherable) || current&.voucherable
    self.order_url = current&.order_url
    self.internal = current&.internal
  end

  def saved_status_change?
    saved_change_to_status_type? || saved_change_to_status?
  end

  def create_new_status
    statuses.create(status: status, status_type: status_type)
  end

  def voucher_id_changes!
    return unless saved_change_to_user_secrets?
    @prev_voucher_id, @curr_voucher_id = saved_change_to_user_secrets.map { |us| us["voucher_id"] }

    # rubocop:disable Naming/MemoizedInstanceVariableName
    @prev_voucher_id ||= ""
    # rubocop:enable Naming/MemoizedInstanceVariableName
  end

  def saved_voucher_id_change?
    @prev_voucher_id != @curr_voucher_id
  end

  def create_voucher_id_message
    messages.create(message: voucher_id_message, author_role: :provider, scope: :user_direct)
  end

  def voucher_id_message
    if @prev_voucher_id.blank? && @curr_voucher_id.present?
      "Voucher has been granted to you, ID: #{@curr_voucher_id}"
    elsif @prev_voucher_id.present? && @curr_voucher_id.blank?
      "Voucher has been revoked"
    elsif @prev_voucher_id.present? && @curr_voucher_id.present?
      "Voucher ID has been updated: #{@curr_voucher_id}"
    end
  end

  def dispatch_emails
    ProjectItem::OnStatusTypeUpdated.new(self).call if saved_change_to_status_type?
  end
end
