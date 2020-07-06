class AddDescriptionToTargetGroups < ActiveRecord::Migration[6.0]
  def change
    add_column :target_groups, :description, :text
    add_column :target_groups, :eid, :text
  end
end
