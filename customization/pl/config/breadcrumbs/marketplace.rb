# frozen_string_literal: true

crumb :marketplace_root do
  link _("Home"), root_path
end

crumb :profile do
  link _("My profile"), profile_path
  parent :marketplace_root
end

crumb :communities do
  link _("Communities and infrastructures"), communities_path
  parent :marketplace_root
end

crumb :help do
  link _("Help"), help_path
  parent :marketplace_root
end

crumb :about do
  link _("About Marketplace"), about_path
  parent :marketplace_root
end

crumb :target_users do
  link _("Target users"), target_users_path
  parent :marketplace_root
end

crumb :api_docs do
  link _("Marketplace API"), api_docs_path
  parent :marketplace_root
end

crumb :favourites do
  link _("Favourite services"), favourites_path
  parent :marketplace_root
end

crumb :congratulations do |project_item|
  link _("Congratulations"), project_service_path(project_item.project, project_item)
  parent :marketplace_root
end

crumb :all_collections do
  if Mp::Application.config.enable_external_search
    link _("All collections"), "#{Mp::Application.config.search_service_base_url}/search/all_collection"
  else
    link _("All collections"), root_path
  end
end

crumb :services do
  if Mp::Application.config.enable_external_search
    link _("Services"), "#{Mp::Application.config.search_service_base_url}/search/service"
  else
    link _("Services"), services_path(params: (session[:query].blank? ? {} : session[:query]))
  end
  
  parent :all_collections
end

crumb :datasources do
  if Mp::Application.config.enable_external_search
    link _("Data Sources"), "#{Mp::Application.config.search_service_base_url}/search/data_source"
  else
    link _("Data Sources"), services_path(params: (session[:query].blank? ? {} : session[:query]))
  end

  parent :all_collections
end

crumb :service do |service|
  link service.name, service_path(service)
  parent service.is_a?(Datasource) ? :datasources : :services
end

crumb :ordering_configuration do |service|
  link _("Ordering configuration"), service_ordering_configuration_path(service, from: params[:from])
  parent :service, service
end

crumb :ordering_configuration_offer_new do |service|
  link _("New offer"), new_service_ordering_configuration_offer_path(service)
  parent :ordering_configuration, service
end

crumb :ordering_configuration_offer_edit do |offer|
  link _("Edit"), edit_service_ordering_configuration_offer_path(offer, from: params[:from])
  parent :ordering_configuration, offer.service
end

crumb :ordering_configuration_bundle_new do |service|
  link _("New bundle"), new_service_ordering_configuration_bundle_path(service)
  parent :ordering_configuration, service
end

crumb :ordering_configuration_bundle_edit do |bundle|
  link _("Edit"), edit_service_ordering_configuration_bundle_path(bundle.service, bundle, from: params[:from])
  parent :ordering_configuration, bundle.service
end

crumb :comparison do
  link _("Comparison"), comparisons_path(fromc: params[:fromc])
  parent :services
end

crumb :providers do
  if Mp::Application.config.enable_external_search
    link _("Providers"), "#{Mp::Application.config.search_service_base_url}/search/provider"
  else
    link _("Providers"), providers_path
  end

  parent :all_collections
end

crumb :provider do |provider|
  link provider.name, provider_path(provider)
  parent :providers
end

crumb :catalogues do
  if Mp::Application.config.enable_external_search
    link _("Catalogues"), "#{Mp::Application.config.search_service_base_url}/search/catalogue"
  else
    link _("Catalogues"), catalogues_path
  end

  parent :all_collections
end

crumb :catalogue do |catalogue|
  link catalogue.name, catalogue_path(catalogue)
  parent :catalogues
end

crumb :projects do
  link _("My projects"), projects_path
  parent :marketplace_root
end

crumb :project_new do
  link _("New project"), new_project_path
  parent :projects
end

crumb :project do |project|
  link project.name, project_path(project)
  parent :projects
end

crumb :project_edit do |project|
  link _("Edit"), edit_project_path(project)
  parent :project, project
end

crumb :project_item do |project_item|
  if project_item.is_root?
    if project_item.has_children?
      link "Bundle (#{project_item.service.name})", project_service_path(project_item.project, project_item)
    else
      link "Service (#{project_item.service.name})", project_service_path(project_item.project, project_item)
    end
    parent :project, project_item.project
  else
    link "Service (#{project_item.service.name})", project_service_path(project_item.project, project_item)
    parent :project_item, project_item.parent
  end
end

crumb :research_product do |project, rp|
  link _("Research Product"), project_research_product_path(project, rp)
  parent :project, project
end
