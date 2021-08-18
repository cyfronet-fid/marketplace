# frozen_string_literal: true

class DropAffiliation < ActiveRecord::Migration[5.2]
  def up
    remove_column :project_items, :affiliation_id
    drop_table :affiliations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
