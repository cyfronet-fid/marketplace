# frozen_string_literal: true

crumb :marketplace_root do
  link "Home", root_path
end

crumb :profile do
  link "My profile", profile_path
  parent :marketplace_root
end

crumb :services do
  link "Services", services_path(params: (session[:query].blank? ? {} : session[:query]))
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
  link "Service (#{project_item.service.name})",
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
  link "Providers", projects_path
  parent :marketplace_root
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
