# frozen_string_literal: true

class AddResearchAreaRefToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_items, :research_area, foreign_key: true, index: true
  end
end
