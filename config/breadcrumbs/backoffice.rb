# frozen_string_literal: true

crumb :backoffice_root do
  link "Backoffice", backoffice_path
end

crumb :backoffice_services do
  link "Owned Services", backoffice_services_path
  parent :backoffice_root
end

crumb :backoffice_service do |service|
  link service.title, backoffice_service_path(service)
  parent :backoffice_services
end

crumb :backoffice_service_new do
  link "New", new_backoffice_service_path
  parent :backoffice_services
end

crumb :backoffice_service_edit do |service|
  link "Edit", edit_backoffice_service_path(service)
  parent :backoffice_service, service
end

crumb :backoffice_research_areas do
  link "Research Areas", backoffice_research_areas_path
  parent :backoffice_root
end

crumb :backoffice_research_area do |research_area|
  link research_area.name, backoffice_research_area_path(research_area)
  parent :backoffice_research_areas
end

crumb :backoffice_research_area_new do |research_area|
  link research_area.name, new_backoffice_research_area_path(research_area)
  parent :backoffice_research_areas
end

crumb :backoffice_research_area_edit do |research_area|
  link research_area.name, edit_backoffice_research_area_path(research_area)
  parent :backoffice_research_areas
end
