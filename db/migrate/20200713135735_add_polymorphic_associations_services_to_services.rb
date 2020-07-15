class AddPolymorphicAssociationsServicesToServices < ActiveRecord::Migration[6.0]
  def change
    add_column :service_relationships, :type, :string
    remove_index :service_relationships, [:source_id, :target_id]
    add_index :service_relationships, [:source_id, :target_id, :type], unique: true
  end
end
