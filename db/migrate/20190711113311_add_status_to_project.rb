# frozen_string_literal: true

class AddStatusToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :status, :string
    execute("UPDATE projects set status = 'active' where status IS NULL;")
  end
end
