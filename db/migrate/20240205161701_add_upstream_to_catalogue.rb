# frozen_string_literal: true

class AddUpstreamToCatalogue < ActiveRecord::Migration[6.1]
  def change
    add_column :catalogues, :upstream_id, :integer, index: true
    add_foreign_key :catalogues, :catalogue_sources, column: :upstream_id, on_delete: :nullify
  end
end
