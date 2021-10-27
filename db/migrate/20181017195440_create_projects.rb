# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.belongs_to :user, null: false, index: true
    end

    add_index :projects, %i[name user_id], unique: true
  end
end
