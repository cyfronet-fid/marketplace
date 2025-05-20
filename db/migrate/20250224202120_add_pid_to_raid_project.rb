# frozen_string_literal: true
class AddPidToRaidProject < ActiveRecord::Migration[7.2]
  def change
    add_column :raid_projects, :pid, :string
  end
end
