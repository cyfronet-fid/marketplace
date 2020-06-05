# frozen_string_literal: true

namespace :services do
  task update_popularity_ratio: :environment do
    puts "Service popularity ratio update"
    analytics = Google::Analytics.new
    total_views = Analytics::TotalServicesViews.new(analytics).call.to_d
    total_project_items = ProjectItem.all.size > 0 ? ProjectItem.all.size : 1
    Service.find_each do |service|
      path = "/services/#{service.slug}"
      views = Analytics::PageViewsAndRedirects.new(analytics).call(path)[:views].to_d
      project_items = service.project_items_count.to_d
      service.popularity_ratio = 1000 * ((views / total_views) + (project_items / total_project_items))
      puts "#{service.name}: #{service.popularity_ratio}"
      service.save!
    end
  end
end
