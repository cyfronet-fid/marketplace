# frozen_string_literal: true

crumb :root do
  link "Home", root_path
end

crumb :profile do
  link "My profile", profile_path
end

crumb :affiliation do |affiliation|
  link "Affiliation ##{affiliation.iid}", profile_affiliation_path(affiliation)
  parent :profile
end


crumb :affiliation_new do
  link "New Affiliation", new_profile_affiliation_path
  parent :profile
end

crumb :services do
  link "Services", services_path
end

crumb :service do |service|
  link service.title, service_path(service)
  if service.main_category
    parent :category, service.main_category
  else
    parent :services
  end
end

crumb :category do |category|
  link category.name, category_path(category)
  if category.parent
    parent category.parent
  else
    parent :services
  end
end

crumb :project_item do |project_item|
  link "Service (#{project_item.service.title})", project_item_path(project_item)
  parent :projects
end

crumb :projects do
  link "My services", projects_path
  parent :root
end
