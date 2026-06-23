# frozen_string_literal: true

class AllowNullableDeployableServiceV6TextFields < ActiveRecord::Migration[7.2]
  def change
    change_column_null :deployable_services, :description, true
    change_column_null :deployable_services, :tagline, true
  end
end
