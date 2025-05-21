# frozen_string_literal: true

class Project < ApplicationRecord
  include Eventable
  include Messageable
  include Publishable

  CUSTOMER_TYPOLOGIES = {
    single_user: "single_user",
    research: "research",
    private_company: "private_company",
    project: "project"
  }.freeze

  ISSUE_STATUSES = {
    jira_require_migration: 100,
    jira_active: 0,
    jira_deleted: 1,
    jira_uninitialized: 2,
    jira_errored: 3
  }.freeze

  PROJECT_STATUSES = { active: "active", archived: "archived" }.freeze

  enum :status, PROJECT_STATUSES
  enum :customer_typology, CUSTOMER_TYPOLOGIES
  enum :issue_status, ISSUE_STATUSES
  attr_accessor :verified_recaptcha

  belongs_to :user
  has_many :project_research_products, dependent: :destroy
  has_many :research_products, through: :project_research_products
  has_many :project_items, dependent: :destroy
  has_many :project_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :project_scientific_domains

  serialize :country_of_origin, coder: Country
  serialize :countries_of_partnership, coder: Country::Array

  validates :name,
            presence: true,
            length: {
              maximum: 255
            },
            uniqueness: {
              scope: :user,
              message: "Project name need to be unique"
            }
  validates :email, email: true, presence: true, if: :show_additional_fields?

  validates :country_of_origin,
            presence: true,
            inclusion: {
              in: Country.all
            },
            if: %i[single_user_or_private_company? show_additional_fields?]
  validates :customer_typology, presence: true

  validates :organization, length: { maximum: 255 }, unless: :research?
  validates :webpage,
            presence: true,
            mp_url: true,
            length: {
              maximum: 255
            },
            if: %i[single_user_or_community? show_additional_fields?]

  validates :user_group_name, length: { maximum: 255 }, presence: true, if: :research?

  validates :project_owner, length: { maximum: 255 }, presence: true, if: :project?
  validates :project_website_url, mp_url: true, allow_blank: true, length: { maximum: 255 }, if: :project?

  validates :company_name, presence: true, length: { maximum: 255 }, if: :private_company?
  validates :countries_of_partnership,
            presence: true,
            multiselect_choices: {
              collection: Country.all
            },
            if: %i[research_or_project? show_additional_fields?]

  validates :company_website_url, mp_url: true, allow_blank: true, length: { maximum: 255 }, if: :private_company?

  validates :issue_id, presence: true, if: :require_jira_issue?
  validates :issue_key, presence: true, if: :require_jira_issue?
  validates :status, presence: true

  validates :department, length: { maximum: 255 }

  def show_additional_fields?
    # Change to true or delete if necessary. Ref: https://github.com/cyfronet-fid/marketplace/issues/3418
    false
  end

  def single_user_or_community?
    single_user? || research?
  end

  def research_or_project?
    research? || project?
  end

  def single_user_or_private_company?
    single_user? || private_company?
  end

  def country_of_origin=(value)
    super(Country.for(value))
  end

  def countries_of_partnership=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def eventable_identity
    { project_id: id }
  end

  def eventable_attributes
    Set.new
  end

  def items_have_new_messages?
    project_items.map(&:user_has_new_messages?).any?
  end

  def eventable_omses
    project_items
      .map(&:eventable_omses)
      .map { |omses| omses.index_by(&:id) }
      .reduce({}) { |memo, oms_h| memo.merge(oms_h) }
      .values
  end

  private

  def require_jira_issue?
    jira_active? || jira_deleted?
  end
end
