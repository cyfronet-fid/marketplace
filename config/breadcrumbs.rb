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

crumb :provider do |provider|
  link "#{provider.name}", provider_path(provider)
  parent :services
end

crumb :orders do
  link "My services", orders_path
  parent :root
end

crumb :order do |order|
  link "Ordered service (#{order.service.title})", order_path(order)
  parent :orders
end
