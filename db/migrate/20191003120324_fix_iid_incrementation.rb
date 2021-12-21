# frozen_string_literal: true

class FixIidIncrementation < ActiveRecord::Migration[5.2]
  def up
    execute("UPDATE project_items item SET iid = 0")
    execute("SELECT id FROM project_items").each { |pi| execute(<<~SQL) }
          UPDATE project_items item
          SET iid = (SELECT COALESCE(MAX(pi.iid), 0)
          FROM project_items pi WHERE pi.project_id = item.project_id) + 1
          WHERE item.id = #{pi["id"]}
        SQL
  end
end
