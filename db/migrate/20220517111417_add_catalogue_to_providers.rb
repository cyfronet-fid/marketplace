# frozen_string_literal: true

class AddCatalogueToProviders < ActiveRecord::Migration[6.1]
  def change
    add_column :providers, :catalogue, :string
  end
end
