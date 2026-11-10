# frozen_string_literal: true

crumb :admin_root do
  link "Admin", admin_path
end

crumb :admin_jobs do
  link "Delayed jobs", admin_jobs_path
  parent :admin_root
end

crumb :admin_help do
  link "Help builder", admin_help_path
  parent :admin_root
end

crumb :admin_lead do
  link "Lead creator", admin_leads_path
  parent :admin_root
end

crumb :admin_lead_section_edit do
  link "Edit lead section", admin_leads_path
  parent :admin_lead
end

crumb :admin_lead_edit do
  link "Edit lead", admin_leads_path
  parent :admin_lead
end

crumb :admin_lead_section_new do
  link "Create new lead section", admin_leads_path
  parent :admin_lead
end

crumb :admin_lead_new do
  link "Create new lead", admin_leads_path
  parent :admin_lead
end

crumb :admin_tour_feedbacks do
  link "Tour Feedback", admin_tour_feedbacks_path
  parent :admin_root
end

crumb :admin_features do
  link "Features", admin_features_path
  parent :admin_root
end
