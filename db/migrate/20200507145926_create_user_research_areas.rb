# frozen_string_literal: true

class CreateUserResearchAreas < ActiveRecord::Migration[6.0]
  def change
    create_table :user_research_areas do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.belongs_to :research_area, foreign_key: true, index: true

      t.timestamps
    end

    add_index :user_research_areas, %i[user_id research_area_id], unique: true
  end
end
