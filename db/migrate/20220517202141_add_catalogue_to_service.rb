# frozen_string_literal: true

class AddCatalogueToService < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :catalogue, :string
  end
end
