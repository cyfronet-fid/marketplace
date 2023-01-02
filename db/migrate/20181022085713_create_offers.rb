# frozen_string_literal: true

class CreateOffers < ActiveRecord::Migration[5.2]
  def change
    create_table :offers do |t|
      t.string :name
      t.text :description
      t.integer :iid, null: false, index: true
      t.belongs_to :service, null: false, index: true

      t.timestamps
    end
    add_index :offers, %i[service_id iid], unique: true
  end
end
