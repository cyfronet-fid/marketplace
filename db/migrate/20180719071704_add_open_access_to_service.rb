# frozen_string_literal: true

class AddOpenAccessToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :open_access, :boolean, default: false
  end
end
