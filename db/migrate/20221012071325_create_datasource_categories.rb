# frozen_string_literal: true

class CreateDatasourceCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_categories do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :category, foreign_key: true, index: true
      t.boolean :main, null: false, default: false

      t.timestamps
    end

    add_index :datasource_categories, %i[datasource_id category_id], unique: true
  end
end
