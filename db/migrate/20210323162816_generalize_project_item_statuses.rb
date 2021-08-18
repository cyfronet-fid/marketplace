# frozen_string_literal: true

class GeneralizeProjectItemStatuses < ActiveRecord::Migration[6.0]
  def change
    drop_table :project_item_changes

    rename_column :project_items, :status, :status_type
    add_column :project_items, :status, :string, default: "created"
    exec_update "UPDATE project_items set status = status_type"
    change_column_null :project_items, :status, false

    rename_column :statuses, :status, :status_type
    add_column :statuses, :status, :string
    exec_update "UPDATE statuses set status = status_type"
    change_column_null :statuses, :status, false
  end
end
