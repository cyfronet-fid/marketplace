# frozen_string_literal: true

class CreateProjectResearchAreas < ActiveRecord::Migration[5.2]
  def change
    create_table :project_research_areas do |t|
      t.belongs_to :project, index: true, foreign_key: true
      t.belongs_to :research_area, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_index :project_research_areas, %i[project_id research_area_id], unique: true

    execute(
      "UPDATE project_research_areas SET ( project_id, research_area_id ) =
                ( project_items.project_id, project_items.research_area_id )
                FROM project_items WHERE project_items.research_area_id IS NOT NULL"
    )
  end
end
