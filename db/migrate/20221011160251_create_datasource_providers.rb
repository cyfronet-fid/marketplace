# frozen_string_literal: true

class CreateDatasourceProviders < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_providers do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :provider, foreign_key: true, index: true

      t.timestamps
    end

    add_index :datasource_providers, %i[datasource_id provider_id], unique: true
  end
end
