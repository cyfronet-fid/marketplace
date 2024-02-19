# frozen_string_literal: true

class CreateCatalogueDataAdministrators < ActiveRecord::Migration[6.1]
  def change
    create_table :catalogue_data_administrators do |t|
      t.belongs_to :data_administrator, index: true
      t.belongs_to :catalogue, index: true

      t.timestamps
    end
  end
end
