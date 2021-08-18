# frozen_string_literal: true

class AddAncestryToResearchArea < ActiveRecord::Migration[5.2]
  def change
    add_column :research_areas, :ancestry, :string, index: true
    add_column :research_areas, :ancestry_depth, :integer, default: 0
  end
end
