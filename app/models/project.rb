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
  validates :project_name, presence: true, if: :project?
  validates :project_website_url, url: true, presence: true, if: :project?
  validates :company_name, presence: true, if: :private_company?
  validates :company_website_url,  url: true, presence: true, if: :private_company?
  validate  :validate_country_of_collaboration, unless: :single_user?

  private

    def validate_country_of_collaboration
      if !country_of_collaboration.is_a?(Array) ||
          country_of_collaboration.detect { |c| !Country.validator_countries_list.include?(c) }
        errors.add(:country_of_collaboration, "isn't included in countries list")
      end
    end
end
