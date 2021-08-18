# frozen_string_literal: true

class CreateStatus < ActiveRecord::Migration[5.2]
  def change
    create_table :statuses do |t|
      t.belongs_to :author
      t.string :status
      t.text :message
      t.references :status_holder, polymorphic: true, index: true

      t.timestamps
    end
  end
end
