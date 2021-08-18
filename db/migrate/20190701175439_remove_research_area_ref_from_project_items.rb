# frozen_string_literal: true

class RemoveResearchAreaRefFromProjectItems < ActiveRecord::Migration[5.2]
  def change
    remove_reference :project_items, :research_area, index: true
  end
end
