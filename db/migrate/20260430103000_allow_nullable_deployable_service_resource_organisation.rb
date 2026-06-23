# frozen_string_literal: true

class AllowNullableDeployableServiceResourceOrganisation < ActiveRecord::Migration[7.2]
  def change
    change_column_null :deployable_services, :resource_organisation_id, true
  end
end
