# frozen_string_literal: true

class Project < ApplicationRecord
  CUSTOMER_TYPOLOGIES = {
    single_user: "single_user",
    research: "research",
    private_company: "private_company",
    project: "project"
  }

  ISSUE_STATUSES = {
      jira_require_migration: 100,
      jira_active: 0,
      jira_deleted: 1,
      jira_uninitialized: 2,
      jira_errored: 3
  }

  PROJECT_STATUSES = {
    active: "active",
    archived: "archived"
  }

  enum status: PROJECT_STATUSES
  enum customer_typology: CUSTOMER_TYPOLOGIES
  enum issue_status: ISSUE_STATUSES

  belongs_to :user
  has_many :project_items, dependent: :destroy
  has_many :project_research_areas, dependent: :destroy
  has_many :research_areas, through: :project_research_areas
  has_many :messages, as: :messageable, dependent: :destroy

  serialize :country_of_origin, Country
  serialize :countries_of_partnership, Country::Array

  validates :name,
            presence: true,
            uniqueness: { scope: :user, message: "Project name need to be unique" }
  validates :email, presence: true
  validates :reason_for_access, presence: true
  validates :country_of_origin, presence: true, if: :single_user_or_private_company?,
            inclusion: { in: Country.all }
  validates :customer_typology, presence: true

  validates :organization, presence: true, if: :single_user_or_community?
  validates :webpage, presence: true, mp_url: true, if: :single_user_or_community?

  validates :user_group_name, presence: true, if: :research?

  validates :project_name, presence: true, if: :project?
  validates :project_website_url, mp_url: true, presence: true, if: :project?

  validates :company_name, presence: true, if: :private_company?
  validates :countries_of_partnership, presence: true, if: :research_or_project?,
            multiselect_choices: { collection: Country.all }
  validates :company_website_url, mp_url: true, presence: true, if: :private_company?

  validates :issue_id, presence: true, if: :require_jira_issue?
  validates :issue_key, presence: true, if: :require_jira_issue?
  validates :status, presence: true

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

  private
    def require_jira_issue?
      jira_active? || jira_deleted?
    end
end
