# frozen_string_literal: true

class CreateServiceCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :service_categories do |t|
      t.belongs_to :service, index: true
      t.belongs_to :category, index: true
      t.boolean :main, null: false, default: false

      t.timestamps null: false
    end
  end
end
