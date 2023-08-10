# frozen_string_literal: true

class CreateResearchProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :research_products do |t|
      t.string :resource_id, null: false
      t.string :resource_type, null: false
      t.string :title, null: false
      t.string :authors, array: true, default: []
      t.string :links, array: true, default: []

      t.timestamps
    end

    create_table :project_research_products do |t|
      t.belongs_to :project, null: false
      t.belongs_to :research_product, null: false
    end

    add_index :research_products, %i[resource_id resource_type], unique: true
    add_index :project_research_products,
              %i[project_id research_product_id],
              unique: true,
              name: "index_on_project_id_and_rp_id"
  end
end
