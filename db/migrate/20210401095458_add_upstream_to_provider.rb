# frozen_string_literal: true

class AddUpstreamToProvider < ActiveRecord::Migration[6.0]
  def change
    change_column :providers, :upstream_id, :integer, index: true
    add_foreign_key :providers, :provider_sources, column: :upstream_id, on_delete: :nullify
  end
end
