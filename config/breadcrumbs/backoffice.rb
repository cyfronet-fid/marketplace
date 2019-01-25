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
  link "New", new_backoffice_research_area_path(research_area)
  parent :backoffice_research_areas
end

crumb :backoffice_research_area_edit do |research_area|
  link "Edit", edit_backoffice_research_area_path(research_area)
  parent :backoffice_research_area, research_area
end

crumb :backoffice_categories do
  link "Categories", backoffice_categories_path
  parent :backoffice_root
end

crumb :backoffice_category do |category|
  link category.name, backoffice_category_path(category)
  parent :backoffice_categories
end

crumb :backoffice_category_new do |category|
  link "New", new_backoffice_category_path(category)
  parent :backoffice_categories
end

crumb :backoffice_category_edit do |category|
  link "Edit", edit_backoffice_category_path(category)
  parent :backoffice_category, category
end

crumb :backoffice_providers do
  link "Providers", backoffice_providers_path
  parent :backoffice_root
end

crumb :backoffice_provider do |provider|
  link provider.name, backoffice_provider_path(provider)
  parent :backoffice_providers
end

crumb :backoffice_provider_new do |provider|
  link "New", new_backoffice_provider_path(provider)
  parent :backoffice_providers
end

crumb :backoffice_provider_edit do |provider|
  link "Edit", edit_backoffice_provider_path(provider)
  parent :backoffice_provider, provider
end

crumb :backoffice_platforms do
  link "Platforms", backoffice_platforms_path
  parent :backoffice_root
end

crumb :backoffice_platform do |platform|
  link platform.name, backoffice_platform_path(platform)
  parent :backoffice_platforms
end

crumb :backoffice_platform_new do |platform|
  link "New", new_backoffice_platform_path(platform)
  parent :backoffice_platforms
end

crumb :backoffice_platform_edit do |platform|
  link "Edit", edit_backoffice_platform_path(platform)
  parent :backoffice_platform, platform
end
