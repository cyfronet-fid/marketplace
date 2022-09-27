# frozen_string_literal: true

class CreateDatasourceCatalogues < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_catalogues do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :catalogue, foreign_key: true, index: true

      t.timestamps
    end
    add_index :datasource_catalogues, %i[datasource_id catalogue_id], unique: true
  end
end
