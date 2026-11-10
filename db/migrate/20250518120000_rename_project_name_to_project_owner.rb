# frozen_string_literal: true

# pl-marketplace and whitelabel-marketplace ran this rename as 20250510072744;
# only marketplace used this version. Their databases already have
# project_owner, so the rename is skipped there instead of failing on the
# missing column.
class RenameProjectNameToProjectOwner < ActiveRecord::Migration[7.2]
  def up
    rename_column :projects, :project_name, :project_owner if column_exists?(:projects, :project_name)
  end

  def down
    rename_column :projects, :project_owner, :project_name
  end
end
