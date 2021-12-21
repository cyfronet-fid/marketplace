# frozen_string_literal: true

class CreateServiceTargetGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :service_target_groups do |t|
      t.belongs_to :service, foreign_key: true, index: true
      t.belongs_to :target_group, foreign_key: true, index: true
      t.timestamps
    end
    add_index :service_target_groups, %i[service_id target_group_id], unique: true
  end
end
