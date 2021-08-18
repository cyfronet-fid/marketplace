# frozen_string_literal: true

class AddUpstreamToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :upstream_id, :integer, index: true
    add_foreign_key :services, :service_sources, column: :upstream_id, on_delete: :nullify
  end
end
