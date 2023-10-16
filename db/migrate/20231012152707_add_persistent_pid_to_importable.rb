# frozen_string_literal: true

class AddPersistentPidToImportable < ActiveRecord::Migration[6.1]
  def change
    %i[providers services].each { |table| add_column table, :ppid, :string }
    add_column :services, :datasource_id, :string
  end
end
