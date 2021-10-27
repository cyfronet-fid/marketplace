# frozen_string_literal: true

class AddIidToProjectItem < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :iid, :integer
    add_index :project_items, :iid
    execute(
      <<~SQL.squish
        UPDATE project_items
        SET iid =
        (
          SELECT COALESCE(MAX(pi.iid), 0)
          FROM project_items pi
          WHERE project_items.project_id = pi.project_id
        ) + 1
      SQL
    )
  end

  def down
    remove_column :project_items, :iid
  end
end
