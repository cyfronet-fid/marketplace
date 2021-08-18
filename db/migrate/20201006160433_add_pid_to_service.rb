# frozen_string_literal: true

class AddPidToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :pid, :string
  end
end
