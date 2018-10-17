class AddProjectRefToProjectItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_items, :project, foreign_key: true
  end
end
