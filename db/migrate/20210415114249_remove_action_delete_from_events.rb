# frozen_string_literal: true

class RemoveActionDeleteFromEvents < ActiveRecord::Migration[6.0]
  def change
    exec_delete "DELETE FROM events WHERE eventable_id IS NULL"
    change_column_null :events, :eventable_id, false
    remove_column :events, :additional_info
  end
end
