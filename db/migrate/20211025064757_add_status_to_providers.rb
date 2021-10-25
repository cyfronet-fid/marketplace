# frozen_string_literal: true

class AddStatusToProviders < ActiveRecord::Migration[6.1]
  def up
    add_column :providers, :status, :string
    execute("UPDATE providers set status = 'published'")
  end

  def down
    remove_column :providers, :status
  end
end
