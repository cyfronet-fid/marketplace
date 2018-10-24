class CreateOffers < ActiveRecord::Migration[5.2]
  def change
    create_table :offers do |t|
      t.string :name
      t.text :description
      t.integer :iid, null: false, index: true
      t.belongs_to :service, nill: false, index: true

      t.timestamps
    end
    add_index :offers, [:service_id, :iid], unique: true
  end
end
