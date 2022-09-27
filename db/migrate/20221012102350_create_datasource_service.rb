# frozen_string_literal: true

class CreateDatasourceService < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_services do |t|
      t.belongs_to :datasource, index: true, foreign_key: true
      t.belongs_to :service, index: true, foreign_key: true
      t.string :type

      t.timestamps
    end
    add_index :datasource_services,
              %i[datasource_id service_id type],
              unique: true,
              name: "index_datasource_id_on_service_and_type"
  end
end
