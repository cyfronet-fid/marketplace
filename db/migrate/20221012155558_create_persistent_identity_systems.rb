# frozen_string_literal: true

class CreatePersistentIdentitySystems < ActiveRecord::Migration[6.1]
  def change
    create_table :persistent_identity_systems do |t|
      t.belongs_to :datasource, index: true, null: false, foreign_key: true
      t.belongs_to :entity_type, index: true

      t.timestamps
    end
    add_index :persistent_identity_systems, %i[datasource_id entity_type_id], name: "index_persistent_id_systems"
    add_index :persistent_identity_systems,
              %i[id entity_type_id],
              name: "index_persistent_id_systems_on_self_and_entity_type"
  end
end
