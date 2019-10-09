# frozen_string_literal: true

require "import/eic"

namespace :import do
  desc "Imports services data from external providers"

  task eic: :environment do
    Import::EIC.new(ENV["MP_IMPORT_EIC_URL"] || "https://catalogue.eosc-portal.eu",
                    dry_run: ENV["DRY_RUN"] || false,
                    default_upstream: (ENV["UPSTREAM"] || "mp").to_sym,
                    dont_create_providers: ENV["DONT_CREATE_PROVIDERS"] || false,
                    ids: (ENV["IDS"] || "").split(","),
                    filepath: ENV["OUTPUT"]).call
  end
end
