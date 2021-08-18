# frozen_string_literal: true

class ChangeTargetGroupToTargetUsers < ActiveRecord::Migration[6.0]
  def change
    rename_table :target_groups, :target_users
    rename_table :service_target_groups, :service_target_users
    rename_column :service_target_users, :target_group_id, :target_user_id
  end
end
