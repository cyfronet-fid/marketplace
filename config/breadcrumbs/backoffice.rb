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
