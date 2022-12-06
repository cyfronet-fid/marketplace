# frozen_string_literal: true

require "securerandom"

namespace :projects do
  desc "Remove default projects without services attached"
  task migrate_from_affiliation: :environment do
    Project.transaction do
      Project
        .includes(:project_items, user: :affiliations)
        .find_each do |project|
          if to_remove?(project)
            destroy!(project)
          elsif to_fill_in?(project)
            fill_in!(project)
          end
        end
    end
  end

  def to_remove?(project)
    project.name == "Services" && project.project_items.empty?
  end

  def to_fill_in?(project)
    project.customer_typology.nil? || project.single_user? || project.research?
  end

  def destroy!(project)
    project.destroy!
  end

  def fill_in!(project)
    if project.user.affiliations.empty?
      puts "Unable to fill in project #{project.name} for #{project.user.full_name} (#{project.user.email})"
    else
      project.customer_typology = "single_user" if project.customer_typology.nil?
      affiliation = project.user.affiliations.first

      project.email = affiliation.email if project.email.blank?
      project.organization ||= affiliation.organization if project.organization.blank?
      project.department = affiliation.department if project.department.blank?
      project.webpage = affiliation.webpage if project.webpage.blank?
      project.reason_for_access = "Not specified" if project.reason_for_access.blank?
      project.user_group_name = "Not speficied" if project.user_group_name.blank?

      project.save!(validate: false)
    end
  end
end
