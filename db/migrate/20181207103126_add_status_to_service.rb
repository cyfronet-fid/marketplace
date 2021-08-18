# frozen_string_literal: true

class AddStatusToService < ActiveRecord::Migration[5.2]
  def up
    add_column :services, :status, :string
    execute("UPDATE services set status = 'published'")
  end

  def down
    remove_column :services, :status
  end
end
