# frozen_string_literal: true

class CreateLeads < ActiveRecord::Migration[6.0]
  def change
    create_table :leads do |t|
      t.string :header, null: false
      t.string :body, null: false
      t.string :url, null: false
      t.belongs_to :lead_section, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
