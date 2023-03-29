# frozen_string_literal: true

crumb :backoffice_root do
  link "Backoffice", backoffice_path
end

crumb :backoffice_services do |category|
  if category
    link category.name, backoffice_category_services_path(category_id: category)
    if category.parent
      parent :backoffice_services, category.parent
    else
      parent :backoffice_services
    end
  else
    link "Owned Services", backoffice_services_path
    parent :backoffice_root
  end
end

crumb :backoffice_service do |service|
  link service.name, backoffice_service_path(service)
  parent :backoffice_services
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

crumb :backoffice_service_new do
  link "New", new_backoffice_service_path
  parent :backoffice_services
end

crumb :backoffice_service_edit do |service|
  link "Edit", edit_backoffice_service_path(service)
  parent :backoffice_service, service
end

crumb :backoffice_service_preview do |service|
  link "Preview"
  if service.persisted?
    parent :backoffice_service, service
  else
    parent :backoffice_services
  end
end

crumb :backoffice_offer_new do |service|
  link "New", new_backoffice_service_offer_path(service)
  parent :backoffice_service, service
end

crumb :backoffice_offer_edit do |offer|
  link "Edit", edit_backoffice_service_offer_path(offer)
  parent :backoffice_service, offer.service
end

crumb :backoffice_bundle_new do |bundle|
  link "New", backoffice_service_path(bundle.service)
  parent :backoffice_service, bundle.service
end

crumb :backoffice_bundle_edit do |bundle|
  link "Edit", edit_backoffice_service_bundle_path(bundle)
  parent :backoffice_service, bundle.service
end
crumb :backoffice_datasources do
  link "Owned Datasources", backoffice_datasources_path
  parent :backoffice_root
end

crumb :backoffice_datasource do |datasource|
  link datasource.name, backoffice_datasource_path(datasource)
  parent :backoffice_datasources
end

crumb :backoffice_datasource_new do |datasource|
  link datasource.name, new_backoffice_datasource_path(datasource)
  parent :backoffice_datasources
end

crumb :backoffice_datasource_edit do |datasource|
  link datasource.name, edit_backoffice_datasource_path(datasource)
  parent :backoffice_datasource, datasource
end

crumb :backoffice_scientific_domains do
  link "Scientific Domains", backoffice_scientific_domains_path
  parent :backoffice_root
end

crumb :backoffice_scientific_domain do |scientific_domain|
  link scientific_domain.name, backoffice_scientific_domain_path(scientific_domain)
  parent :backoffice_scientific_domains
end

crumb :backoffice_scientific_domain_new do |scientific_domain|
  link "New", new_backoffice_scientific_domain_path(scientific_domain)
  parent :backoffice_scientific_domains
end

crumb :backoffice_scientific_domain_edit do |scientific_domain|
  link "Edit", edit_backoffice_scientific_domain_path(scientific_domain)
  parent :backoffice_scientific_domain, scientific_domain
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
  link "Providers", backoffice_providers_path(page: params[:page])
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

crumb :backoffice_vocabularies do |type|
  link type, send("backoffice_#{type.parameterize(separator: "_").pluralize}_path")
  parent :backoffice_root
end

crumb :backoffice_vocabulary do |vocabulary, type|
  link vocabulary.name, send("backoffice_#{type.parameterize(separator: "_")}_path", vocabulary)
  parent :backoffice_vocabularies, type
end

crumb :backoffice_vocabulary_new do |type|
  link "New", send("new_backoffice_#{type.parameterize(separator: "_")}_path")
  parent :backoffice_vocabularies, type
end

crumb :backoffice_vocabulary_edit do |vocabulary, type|
  link "Edit", send("edit_backoffice_#{type.parameterize(separator: "_")}_path", vocabulary)
  parent :backoffice_vocabulary, vocabulary, type
end
