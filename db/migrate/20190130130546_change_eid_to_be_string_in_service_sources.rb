# frozen_string_literal: true

class ChangeEidToBeStringInServiceSources < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up { change_column :service_sources, :eid, :string }
      dir.down do
        execute("DELETE FROM service_sources")
        change_column :service_sources, :eid, :integer, using: "eid::integer"
      end
    end
  end
end
