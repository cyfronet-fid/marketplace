# frozen_string_literal: true

class CreateServiceOpinions < ActiveRecord::Migration[5.2]
  def change
    create_table :service_opinions do |t|
      t.integer :rating, null: false
      t.text :opinion
      t.belongs_to :project_item, null: false, index: true

      t.timestamps
    end
  end
end
