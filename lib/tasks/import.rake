# frozen_string_literal: true

require "import/eic"

namespace :import do
  desc "Imports services data from external providers"

  task eic: :environment do
    Import::EIC.new(ENV["MP_IMPORT_EIC_URL"] || "http://beta.einfracentral.eu",
                    ENV["DRY_RUN"] || false,
                    ENV["DONT_CREATE_PROVIDERS"] || false).call
  end
end
