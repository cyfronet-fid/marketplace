# frozen_string_literal: true

class CreateMessage < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.belongs_to :author
      t.text :message
      t.integer :iid
      t.references :messageable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
