# frozen_string_literal: true

class SwitchInfrastructuresToAdm < ActiveRecord::Migration[7.2]
  def change
    rename_column :infrastructures, :im_infrastructure_id, :deployment_id
    rename_column :infrastructures, :im_base_url, :api_base_url
    add_column :infrastructures, :allocation_id, :string
  end
end
