# frozen_string_literal: true

class AddConversationLastSeen < ActiveRecord::Migration[6.1]
  def up
    add_column :projects, :conversation_last_seen, :datetime
    add_column :project_items, :conversation_last_seen, :datetime
    execute("UPDATE projects SET conversation_last_seen = '#{Time.now}'")
    execute("UPDATE project_items SET conversation_last_seen = '#{Time.now}'")
    change_column_null :projects, :conversation_last_seen, false
    change_column_null :project_items, :conversation_last_seen, false
  end

  def down
    remove_column :projects, :conversation_last_seen
    remove_column :project_items, :conversation_last_seen
  end
end
