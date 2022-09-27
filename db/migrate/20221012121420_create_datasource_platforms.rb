# frozen_string_literal: true

class CreateDatasourcePlatforms < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_platforms do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :platform, foreign_key: true, index: true
      t.timestamps
    end
    add_index :datasource_platforms, %i[datasource_id platform_id], unique: true
  end
end
