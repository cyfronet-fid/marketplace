# frozen_string_literal: true

require "sentry-ruby"

namespace :import do
  desc "Imports services data from external providers"

  task resources: :environment do
    Import::Resources.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://beta.providers.eosc-portal.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task providers: :environment do
    Import::Providers.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://beta.providers.eosc-portal.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task vocabularies: :environment do
    Import::Vocabularies.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://beta.providers.eosc-portal.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task catalogues: :environment do
    Import::Catalogues.new(
      ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api",
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task datasources: :environment do
    Import::Datasources.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://beta.providers.eosc-portal.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      ids: ENV.fetch("IDS", "").split(","),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task guidelines: :environment do
    Import::Guidelines.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://beta.providers.eosc-portal.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end
end
