# frozen_string_literal: true

module BundlesHelper
  # pl and whitelabel replaced marketplace locations with research activities.
  BUNDLE_DETAILS_FIELDS =
    if Mp::Variant.marketplace?
      %i[bundle_goals capabilities_of_goals marketplace_locations scientific_domains].freeze
    else
      %i[bundle_goals capabilities_of_goals research_activities scientific_domains].freeze
    end
end
