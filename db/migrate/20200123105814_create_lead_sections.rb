# frozen_string_literal: true

class CreateLeadSections < ActiveRecord::Migration[6.0]
  def change
    create_table :lead_sections do |t|
      t.string :slug, unique: true, null: false
      t.string :title, null: false
      t.string :template, null: false

      t.timestamps
    end
  end
end
