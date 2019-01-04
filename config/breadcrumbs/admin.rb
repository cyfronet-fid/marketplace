# frozen_string_literal: true

crumb :admin_root do
  link "Admin", admin_path
end

crumb :admin_jobs do
  link "Delayed jobs", admin_jobs_path
  parent :admin_root
end
