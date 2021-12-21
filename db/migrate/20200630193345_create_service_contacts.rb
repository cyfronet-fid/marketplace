# frozen_string_literal: true

class CreateServiceContacts < ActiveRecord::Migration[6.0]
  def change
    create_table :contacts do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :phone
      t.string :position
      t.string :organisation
      t.string :contactable_type
      t.string :type
      t.belongs_to :contactable, index: true, null: false
      t.timestamps
    end
    add_index :contacts, %i[id contactable_id contactable_type], unique: true
  end
end
