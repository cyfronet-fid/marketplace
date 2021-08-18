# frozen_string_literal: true

class CreateTourHistories < ActiveRecord::Migration[6.0]
  def change
    create_table :tour_histories do |t|
      t.string :controller_name
      t.string :action_name
      t.string :tour_name
      t.references :user, null: false, foreign_key: true

      t.timestamps index: true
    end
  end
end
