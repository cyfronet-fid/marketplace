# frozen_string_literal: true

class CreateHelpSections < ActiveRecord::Migration[6.0]
  def change
    create_table :help_sections do |t|
      t.string :title, null: false
      t.string :slug, unique: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
