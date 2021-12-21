# frozen_string_literal: true

class ChangeResearchAreaNameUniquenessScope < ActiveRecord::Migration[5.2]
  def change
    remove_index :research_areas, :name
    add_index :research_areas, %i[name ancestry], unique: true
  end
end
