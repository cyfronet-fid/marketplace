class CreateOmsAdministrations < ActiveRecord::Migration[6.0]
  def change
    create_table :oms_administrations do |t|
      t.references :oms, null: false, foreign_key: true, index:true
      t.references :user, null: false, foreign_key: true, index:true

      t.timestamps null: false
    end

    add_index :oms_administrations, [:oms_id, :user_id], unique: true
  end
end
