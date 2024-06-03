# frozen_string_literal: true

class RaidProject < ApplicationRecord
   
  attr_accessor :form_step
  belongs_to :user
  
  with_options dependent: :destroy, autosave: true, inverse_of: :raid_project do |assoc|
    assoc.has_one :main_title, class_name: "Raid::MainTitle"
    assoc.has_many :alternative_titles, class_name: "Raid::AlternativeTitle"
    assoc.has_many :raid_organisations, class_name: "Raid::RaidOrganisation"
    assoc.has_one :main_description, class_name: "Raid::MainDescription"
    assoc.has_many :alternative_descriptions, class_name: "Raid::AlternativeDescription"
    assoc.has_one :raid_access, class_name: "Raid::RaidAccess"
    assoc.has_many :contributors, class_name: "Raid::Contributor"
  end

  with_options  allow_destroy: true do |nested_attrs|
    nested_attrs.accepts_nested_attributes_for :main_title
    nested_attrs.accepts_nested_attributes_for :alternative_titles
    nested_attrs.accepts_nested_attributes_for :main_description
    nested_attrs.accepts_nested_attributes_for :alternative_descriptions
    nested_attrs.accepts_nested_attributes_for :contributors 
    nested_attrs.accepts_nested_attributes_for :raid_organisations
    nested_attrs.accepts_nested_attributes_for :raid_access
  end
  
  validates_associated :main_title

  with_options  if: -> { required_for_step?(1) } do
    validates :start_date, presence: true
    validates :main_title, presence: true
    validate :validate_dates
  end
  
  with_options if: -> { required_for_step?(2) } do
    validates :contributors, presence: true
    validate :contributors, :validate_leader, :validate_contact
  end
  
  with_options if: -> { required_for_step?(3) } do
    validate :raid_organisations, :validate_organisations
  end

  with_options presence: true, if: -> { required_for_step?(4) } do
    validates :raid_access
  end

  before_validation :clear_description


  def required_for_step?(step)
    # All fields are required if no form step is present
    return true if form_step.nil?

    current_step = form_step[-1].to_i

    # All fields from previous steps are required
    step <= current_step
  end

  def clear_description
    if main_description.present? && main_description.text.empty? && main_description.language.empty?
      main_description.destroy
    end
  end

  def validate_organisations
    lead = false
    raid_organisations.each do |organisation|
      if organisation.position.pid == "lead-research-organisation"
        if !lead
          lead = true
        else
          errors.add(:org_base, "Only one organisation can have Lead research organisation position")
          break
        end
      end
      errors.add(:org_base, "One (and only one) organisation must have Lead research organisation position") unless lead
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
    errors.add(:contributor_base, "At least one contributor must be a project leader") if leader == false
  end

  def validate_contact
    contact = false
    contributors.each do |contributor|
      if contributor.contact == true
        contact = true
        break
      end
    end
    errors.add(:contributor_base, "At least one contributor must be a project contact") if contact == false
  end

  def validate_dates
    errors.add(:end_date, "cannot precede start date") if end_date && start_date >= end_date
  end

end
