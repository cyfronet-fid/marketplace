# frozen_string_literal: true

# Re-adds the column dropped by StripServiceToV6 (20260429141000). The
# `marketplace` variant never populates or reads it (Api::ServicesController
# keeps returning `[]` for it, per ADR-0001's controller audit), but
# `pl`/`whitelabel` variants need it back to serve real COUNTRY_NAME data.
# `if_not_exists` guards a pl/whitelabel DB where this table was carried over
# from before the strip and never lost the column in the first place.
class AddGeographicalAvailabilitiesToServices < ActiveRecord::Migration[7.2]
  def change
    add_column :services, :geographical_availabilities, :string, array: true, default: [], if_not_exists: true
  end
end
