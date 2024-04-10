# frozen_string_literal: true

class RaidProject < ApplicationRecord
  belongs_to :user
  has_one :main_title, class_name: "Raid::MainTitle", dependent: :destroy, autosave: true, inverse_of: :raid_project
  has_many :alternative_titles,
          class_name: "Raid::AlternativeTitle",
          dependent: :destroy,
          autosave: true,
          inverse_of: :raid_project
  has_many :raid_organisations,
          class_name: "Raid::RaidOrganisation",
          dependent: :destroy,
          autosave: true,
          inverse_of: :raid_project
  has_one :main_description,
          class_name: "Raid::MainDescription", 
          dependent: :destroy, 
          autosave: true, 
          inverse_of: :raid_project,
          required: false
  has_many :alternative_descriptions,
          class_name: "Raid::AlternativeDescription",
          dependent: :destroy,
          autosave: true,
          inverse_of: :raid_project
  has_many :contributors,
          class_name: "Raid::Contributor",
          dependent: :destroy,
          autosave: true

  accepts_nested_attributes_for :main_title, allow_destroy: true
  accepts_nested_attributes_for :raid_organisations, allow_destroy: true
  validates_associated :main_title
  accepts_nested_attributes_for :alternative_titles, allow_destroy: true
  accepts_nested_attributes_for :main_description, allow_destroy: true
  accepts_nested_attributes_for :alternative_descriptions, allow_destroy: true
  accepts_nested_attributes_for :contributors, allow_destroy: true

  validates :main_title, presence: true
  validates :start_date, presence: true
  validates :contributors, presence: true
  validate :contributors,  :validate_leader, :validate_contact
  validate :raid_organisations, :validate_organisations

  validate :validate_dates
  before_validation :clear_description


  def clear_description
    if main_description.present? && main_description.text.empty? && main_description.language.empty?
      main_description.destroy
    end
  end

  def validate_organisations
    lead = false
    raid_organisations.each do |organisation|
       if organisation.position.pid == "lead-research-organisation"
          p !lead
          unless lead
            lead = true
          else
            errors.add(:org_base, "Only one organisation can have Lead research organisation position")
            break
        end
       end
    unless lead
      errors.add(:org_base, "One (and only one) organisation must have Lead research organisation position")
    end
  end
  end

  def validate_leader
    leader = false
    contributors.each do |contributor|
      if contributor.leader == true
        leader = true
        break
      end
    end
    if leader == false
      errors.add(:contributor_base, "At least one contributor must be a project leader")
    end
  end

  def validate_contact
    contact = false
    contributors.each do |contributor|
      if contributor.contact == true
        contact = true
        break
      end
    end
    if contact == false
      errors.add(:contributor_base, "At least one contributor must be a project contact")
    end
  end

  def validate_dates
    if end_date && start_date >= end_date
      errors.add(:end_date, "cannot precede start date")
    end
  end
end
