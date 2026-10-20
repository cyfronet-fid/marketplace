# frozen_string_literal: true

require "sentry-ruby"

namespace :import do
  desc "Imports services data from external providers"

  task authorize: :environment do
    # whitelabel always imports with a client credentials token.
    if Mp::Variant.whitelabel?
      ENV["MP_IMPORT_TOKEN"] = Importers::ClientCredentialsToken.new.receive_token if ENV["MP_IMPORT_TOKEN"].blank?
    elsif ENV["MP_IMPORT_TOKEN"].present?
      next
    elsif Importers::ClientCredentialsToken.partially_configured?
      Importers::ClientCredentialsToken.new.receive_token
    elsif Importers::ClientCredentialsToken.configured?
      ENV["MP_IMPORT_TOKEN"] = Importers::ClientCredentialsToken.new.receive_token
    end
  end

  task all: %i[environment authorize] do
    collections = %w[vocabularies catalogues providers resources datasources guidelines]
    collections << "deployable_services" if Mp::Variant.marketplace?

    collections.each do |collection|
      Rake::Task["import:#{collection}"].invoke
    end
  end

  task resources: %i[environment authorize] do
    Import::Resources.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil),
      rescue_mode: ActiveModel::Type::Boolean.new.cast(ENV.fetch("MP_IMPORT_RESCUE_MODE", false))
    ).call
  end

  task providers: %i[environment authorize] do
    Import::Providers.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil),
      rescue_mode: ActiveModel::Type::Boolean.new.cast(ENV.fetch("MP_IMPORT_RESCUE_MODE", false))
    ).call
  end

  task vocabularies: %i[environment authorize] do
    Import::Vocabularies.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task catalogues: %i[environment authorize] do
    Import::Catalogues.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task datasources: %i[environment authorize] do
    Import::Datasources.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      ids: ENV.fetch("IDS", "").split(","),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end

  task deployable_services: %i[environment authorize] do
    next unless Mp::Variant.marketplace?

    Import::DeployableServices.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      default_upstream: ENV.fetch("UPSTREAM", "eosc_registry").to_sym,
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil),
      rescue_mode: ActiveModel::Type::Boolean.new.cast(ENV.fetch("MP_IMPORT_RESCUE_MODE", false))
    ).call
  end

  task guidelines: %i[environment authorize] do
    Import::Guidelines.new(
      ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api"),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false)),
      filepath: ENV.fetch("OUTPUT", nil),
      token: ENV.fetch("MP_IMPORT_TOKEN", nil)
    ).call
  end
end
