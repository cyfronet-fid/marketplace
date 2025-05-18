# frozen_string_literal: true

class RenameProjectNameToProjectOwner < ActiveRecord::Migration[7.2]
  def change
    rename_column :projects, :project_name, :project_owner
  end
end
