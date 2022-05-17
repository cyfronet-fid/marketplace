# frozen_string_literal: true

class AddCatalogueToProviders < ActiveRecord::Migration[6.1]
  def up
    add_column :providers, :catalogue, :string
    execute("UPDATE providers set catalogue = 'CatRIS'")
  end

  def down
    remove_column :providers, :catalogue
  end
end
