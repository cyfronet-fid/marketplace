# frozen_string_literal: true

class CreateDataAdministrators < ActiveRecord::Migration[6.0]
  def change
    create_table :data_administrators do |t|
      t.string :first_name, index: true
      t.string :last_name, index: true
      t.string :email, null: false, index: true

      t.timestamps
    end
  end
end
