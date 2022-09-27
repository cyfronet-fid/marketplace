# frozen_string_literal: true

class CreateDatasourceTargetGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_target_users do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :target_user, foreign_key: true, index: true
      t.timestamps
    end
    add_index :datasource_target_users,
              %i[datasource_id target_user_id],
              unique: true,
              name: "index_datasource_target_users"
  end
end
