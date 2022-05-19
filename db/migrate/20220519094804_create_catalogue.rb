# frozen_string_literal: true

class CreateCatalogue < ActiveRecord::Migration[6.1]
  def change
    create_table :catalogues do |t|
      t.string :name, null: false
      t.string :pid, null: true
      t.timestamps
    end
  end
end
