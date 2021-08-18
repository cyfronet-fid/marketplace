# frozen_string_literal: true

class CreateResearchAreas < ActiveRecord::Migration[5.2]
  def change
    create_table :research_areas do |t|
      t.text :name, null: false
    end
  end
end
