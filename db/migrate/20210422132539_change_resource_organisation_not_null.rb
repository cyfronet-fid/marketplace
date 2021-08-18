# frozen_string_literal: true

class ChangeResourceOrganisationNotNull < ActiveRecord::Migration[6.0]
  def up
    change_column_null(:services, :resource_organisation_id, false)
  end

  def down
    change_column_null(:services, :resource_organisation_id, true)
  end
end
