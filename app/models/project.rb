# frozen_string_literal: true

class Project < ApplicationRecord
  enum customer_typology: ProjectItem::CUSTOMER_TYPOLOGIES

  countries_list = Country.validator_countries_list

  belongs_to :user
  has_many :project_items, dependent: :destroy


  validates :name,
            presence: true,
            uniqueness: { scope: :user, message: "Project name need to be unique" }

  validates :country_of_customer, presence: true, inclusion: { in: countries_list }
  validates :user_group_name, presence: true, if: :research?
  validates :country_of_collaboration, presence: true, unless: :single_user?
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url,  url: true, presence: true, if: :private_company?
end
