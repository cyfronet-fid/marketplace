# frozen_string_literal: true

class ProjectItem < ApplicationRecord
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
  has_one :service_opinion, dependent: :restrict_with_error
  has_many :project_item_changes, dependent: :destroy

  validates :offer, presence: true
  validates :affiliation, presence: true, unless: :open_access?
  validates :project, presence: true
  validates :status, presence: true
  validates :customer_typology, presence: true, unless: :open_access?
  validates :access_reason, presence: true, unless: :open_access?
  validates_associated :property_values
  validates :user_group_name, presence: true, if: :research?
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url, url: true, presence: true, if: :private_company?

  delegate :user, to: :project

  def service
    offer.service unless offer.nil?
  end

  before_save :map_properties

  validate :one_per_project?, on: :create

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

  def to_s
    "##{id}"
  end

  def map_properties
    self.properties = property_values.map(&:to_json)
  end

  attribute :property_values

  def property_values
    if !@property_values
      if properties.nil?
        @property_values = offer.attributes.dup
      else
        @property_values = properties.map { |prop| Attribute.from_json(prop) }
      end
    end
    @property_values
  end

  def property_values=(property_values)
    if property_values.is_a?(Array)
      @property_values = property_values
    elsif property_values.is_a?(Hash)
      props = []
      property_values.each { |id, value|
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

  def one_per_project?
    if open_access?
      project_items_services = Service.joins(offers: { project_items: :project }).
        where(id: service.id, offers: { project_items: { project_id: [ project_id] } }).count.positive?

      errors.add(:project, :repited_in_project, message: "^You cannot add open access service #{service.title} to project #{project.name} twice") unless !project_items_services.present?
    end
  end
end
