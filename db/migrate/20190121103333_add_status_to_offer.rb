# frozen_string_literal: true

class AddStatusToOffer < ActiveRecord::Migration[5.2]
  def up
    add_column :offers, :status, :string
    execute("UPDATE offers set status = 'published'")
  end

  def down
    remove_column :offers, :status
  end
end
