# frozen_string_literal: true

crumb :marketplace_root do
  link "Home", root_path
end

crumb :profile do
  link "My profile", profile_path
  parent :marketplace_root
end

crumb :services do
  link "Resources", services_path(params: (session[:query].blank? ? {} : session[:query]))
  parent :marketplace_root
end

crumb :service do |service|
  link service.name, service_path(service)
  if params[:comp_link]
    parent :comparison
  elsif params[:fromc] && category = service.categories.find_by(slug: params[:fromc])
    parent :category, category
  elsif service.main_category
    parent :category, service.main_category
  else
    parent :services
  end
end

crumb :ordering_configuration do |service|
  link "Ordering configuration", service_ordering_configuration_path(service, from: params[:from])
  parent :service, service
end

crumb :ordering_configuration_offer_new do |service|
  link "New", new_service_ordering_configuration_offer_path(service)
  parent :ordering_configuration, service
end

crumb :ordering_configuration_offer_edit do |offer|
  link "Edit", edit_service_ordering_configuration_offer_path(offer, from: params[:from])
  parent :ordering_configuration, offer.service
end

crumb :resource_details do |service|
  link "Details", service_details_path(service)
  if params[:from]
    parent params[:from].to_sym, service
  else
    parent :service, service
  end
end

crumb :resource_opinions do |service|
  link "Reviews", service_opinions_path(service)
  if params[:from]
    parent params[:from].to_sym, service
  else
    parent :service, service
  end
end

crumb :category do |category|
  link category.name, category_services_path(category, params: (session[:query].blank? ? {} : session[:query]))
  if category.parent
    parent category.parent
  else
    parent :services
  end
end

crumb :comparison do
  link "Comparison", comparisons_path(fromc: params[:fromc])
  if params[:fromc] && category = Category.find_by(slug: params[:fromc])
    parent :category, category
  else
    parent :services
  end
end

crumb :project_item do |project_item|
  link "Resource (#{project_item.service.name})",
    project_service_path(project_item.project, project_item)
  parent :project, project_item.project
end

crumb :projects do
  link "My projects", projects_path
  parent :marketplace_root
end

crumb :congratulations do |project_item|
  link "Congratulations",
       project_service_path(project_item.project, project_item)
  parent :marketplace_root
end

crumb :project_new do
  link "New project", new_project_path
  parent :projects
end

crumb :project do |project|
  link project.name, project_path(project)
  parent :projects
end

crumb :project_edit do |project|
  link "Edit", edit_project_path(project)
  parent :project, project
end

crumb :providers do
  link "Providers", providers_path
  parent :marketplace_root
end

crumb :provider do |provider|
  link provider.name, provider_path(provider)
  parent :providers
end

crumb :communities do
  link "Communities and infrastructures", communities_path
  parent :marketplace_root
end

crumb :help do
  link "Help", help_path
  parent :marketplace_root
end

crumb :about do
  link "About Marketplace", about_path
  parent :marketplace_root
end

crumb :target_users do
  link "Target users", target_users_path
  parent :marketplace_root
end

crumb :api_docs do
  link "Marketplace API", api_docs_path
  parent :marketplace_root
end

crumb :favourites do
  link "Favourite resources", favourites_path
  parent :marketplace_root
end
