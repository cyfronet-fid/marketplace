# frozen_string_literal: true

class ProjectItem < ApplicationRecord
  include Customization

  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    waiting_for_response: "waiting_for_response",
    ready: "ready",
    rejected: "rejected"
  }

  CUSTOMER_TYPOLOGIES = {
    single_user: "single_user",
    research: "research",
    private_company: "private_company",
    project: "project"
  }

  ISSUE_STATUSES = {
      jira_active: 0,
      jira_deleted: 1,
      jira_uninitialized: 2,
      jira_errored: 3
  }

  enum status: STATUSES
  enum issue_status: ISSUE_STATUSES
  enum customer_typology: CUSTOMER_TYPOLOGIES

  belongs_to :offer
  belongs_to :affiliation, required: false
  belongs_to :project
  belongs_to :research_area, required: false
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :project_item_changes, dependent: :destroy

  validates :offer, presence: true
  validates :affiliation, presence: true, unless: :open_access?
  validates :research_area, presence: true, unless: :open_access?
  validates :project, presence: true
  validates :status, presence: true
  validates :customer_typology, presence: true, unless: :open_access?
  validates :access_reason, presence: true, unless: :open_access?
  validate :research_area_is_a_leaf
  validates :user_group_name, presence: true, if: :research?
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url, url: true, presence: true, if: :private_company?
  validates :request_voucher, absence: true, unless: :vaucherable?
  validates :voucher_id, absence: true, if: :voucher_id_unwanted?
  validates :voucher_id, presence: true, allow_blank: false, if: :voucher_id_required?
  validate :one_per_project?, on: :create

  delegate :user, to: :project

  def service
    offer.service unless offer.nil?
  end

  def open_access?
    @is_open_access ||= service&.open_access?
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

    project_item_changes.create(status: self.status, message: message, author: author, iid: iid).tap do
      update_attributes(voucher_id: voucher_id)
    end
  end

  def to_s
    "##{id}"
  end

  def one_per_project?
    if open_access?
      project_items_services = Service.joins(offers: { project_items: :project }).
        where(id: service.id, offers: { project_items: { project_id: [ project_id] } }).count.positive?

      errors.add(:project, :repited_in_project, message: "^You cannot add open access service #{service.title} to project #{project.name} twice") unless !project_items_services.present?
    end
  end

  def research_area_is_a_leaf
    errors.add(:research_area_id, "cannot have children") if research_area&.has_children?
  end

  def vaucherable?
    offer&.voucherable
  end

  def voucher_id_required?
    vaucherable? && request_voucher == false
  end

  def voucher_id_unwanted?
    created? && !voucher_id_required?
  end
end
