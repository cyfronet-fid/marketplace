# frozen_string_literal: true

require "mini_magick"

desc "Remove corrupted logos"
task remove_corrupted_logos: :environment do
  service = Service.where(slug: "gbif-spain-spatial-portal").first
  service.logo.detach
  service.save
end
