# frozen_string_literal: true

class AddProjectRefToProjectItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_items, :project, foreign_key: true, index: true
  end
end
