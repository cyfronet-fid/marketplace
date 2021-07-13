# frozen_string_literal: true

require "import/resources"
require "raven"

namespace :import do
  desc "Imports services data from external providers"

  task resources: :environment do
    Import::Resources.new(ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api",
                    dry_run: ENV["DRY_RUN"] || false,
                    default_upstream: (ENV["UPSTREAM"] || "mp").to_sym,
                    ids: (ENV["IDS"] || "").split(","),
                    filepath: ENV["OUTPUT"],
                    token: ENV["MP_IMPORT_TOKEN"]).call
  end

  task providers: :environment do
    Import::Providers.new(ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api",
                          dry_run: ENV["DRY_RUN"] || false,
                          default_upstream: (ENV["UPSTREAM"] || "mp").to_sym,
                          ids: (ENV["IDS"] || "").split(","),
                          filepath: ENV["OUTPUT"],
                          token: ENV["MP_IMPORT_TOKEN"]).call
  end

  task vocabularies: :environment do
    Import::Vocabularies.new(ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api",
                             dry_run: ENV["DRY_RUN"] || false,
                             filepath: ENV["OUTPUT"],
                             token: ENV["MP_IMPORT_TOKEN"]).call
  end
end
