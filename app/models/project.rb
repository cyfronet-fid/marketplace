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

  enum customer_typology: CUSTOMER_TYPOLOGIES
  enum issue_status: ISSUE_STATUSES
  enum customer_typology: ProjectItem::CUSTOMER_TYPOLOGIES

  belongs_to :user
  has_many :project_items, dependent: :destroy


  validates :name,
            presence: true,
            uniqueness: { scope: :user, message: "Project name need to be unique" }

  def require_jira_issue?
    jira_active? || jira_deleted?
  end

  validates :issue_id, presence: true, if: :require_jira_issue?
  validates :issue_key, presence: true, if: :require_jira_issue?
  validates :customer_typology, presence: true
  validates :reason_for_access, presence: true
  validates :user_group_name, presence: true, if: :research?
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url,  url: true, presence: true, if: :private_company?
end
