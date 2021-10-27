# frozen_string_literal: true

class CreateServiceResearchAreas < ActiveRecord::Migration[5.2]
  def change
    create_table :service_research_areas do |t|
      t.belongs_to :service, index: true, foreign_key: true
      t.belongs_to :research_area, index: true, foreign_key: true

      t.timestamps
    end
    add_index :service_research_areas, %i[service_id research_area_id], unique: true
  end
end
