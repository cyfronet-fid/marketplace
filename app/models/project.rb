# frozen_string_literal: true

class Project < ApplicationRecord
  CUSTOMER_TYPOLOGIES = {
    single_user: "single_user",
    research: "research",
    private_company: "private_company",
    project: "project"
  }

  enum customer_typology: CUSTOMER_TYPOLOGIES

  belongs_to :user
  has_many :project_items, dependent: :destroy


  validates :name,
            presence: true,
            uniqueness: { scope: :user, message: "Project name need to be unique" }

  validates :customer_typology, presence: true
  validates :reason_for_access, presence: true
  validates :user_group_name, presence: true, if: :research?
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url,  url: true, presence: true, if: :private_company?
end
