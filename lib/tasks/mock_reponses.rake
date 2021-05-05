# frozen_string_literal: true

require_relative "../config/vcr_setup"

namespace :mock_responses do
  @@host = "localhost"
  @@port = 5000

  desc "Record responses"
  task record_responses: :environment do
    # services
    puts "Recording services and its resources"
    VCR.use_cassette("services", record: :all) do
      # Index
      Net::HTTP.get_response(@@host, "/services", @@port)
      Net::HTTP.get_response(@@host, "/backoffice/services", @@port)

      # Show
      Service.all.each do |service|
        service_url = "/services/" + service.slug
        Net::HTTP.get_response(@@host, service_url, @@port)
        Net::HTTP.get_response(@@host, service_url + "/offers", @@port)
        Net::HTTP.get_response(@@host, service_url + "/configuration", @@port)
        Net::HTTP.get_response(@@host, service_url + "/information", @@port)
        Net::HTTP.get_response(@@host, service_url + "/summary", @@port)
        Net::HTTP.get_response(@@host, service_url + "/opinions", @@port)
        Net::HTTP.get_response(@@host, service_url + "/details", @@port)
        Net::HTTP.get_response(@@host, service_url + "/ordering_configuration", @@port)

        Net::HTTP.get_response(@@host, "/backoffice/" + service_url, @@port)
        Net::HTTP.get_response(@@host, "/backoffice/" + service_url + "/offers", @@port)
        Net::HTTP.get_response(@@host, "/backoffice/" + service_url + "/logo_preview", @@port)
      end
    end

    # categories
    VCR.use_cassette("categories", record: :all) do
      # Index
      Net::HTTP.get_response(@@host, "/categories", @@port)

      # Services for categories
      Category.all.each do |category|
        services_category_url = "/services/c/" + category.slug
        Net::HTTP.get_response(@@host, services_category_url, @@port)
        Net::HTTP.get_response(@@host, "/backoffice/" + services_category_url, @@port)
      end
    end

    # providers
    VCR.use_cassette("providers", record: :all) do
      # Index
      Net::HTTP.get_response(@@host, "/providers", @@port)
      Net::HTTP.get_response(@@host, "/backoffice/providers", @@port)
    end

    # other
    VCR.use_cassette("other", record: :all) do
      # Index
      Net::HTTP.get_response(@@host, "/target_users", @@port)
      Net::HTTP.get_response(@@host, "/communities", @@port)
      Net::HTTP.get_response(@@host, "/about_projects", @@port)
      Net::HTTP.get_response(@@host, "/backoffice/scientific_domains", @@port)
      Net::HTTP.get_response(@@host, "/backoffice/platforms", @@port)
    end
  end
end
