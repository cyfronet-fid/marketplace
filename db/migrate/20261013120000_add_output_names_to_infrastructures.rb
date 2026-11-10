# frozen_string_literal: true

class AddOutputNamesToInfrastructures < ActiveRecord::Migration[7.2]
  def change
    add_column :infrastructures, :output_names, :string, array: true, default: []
  end
end
