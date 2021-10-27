# frozen_string_literal: true

class CreateOfferLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :offer_links do |t|
      t.belongs_to :source, foreign_key: { to_table: :offers }, null: false
      t.belongs_to :target, foreign_key: { to_table: :offers }, null: false

      t.timestamps
    end
    add_index :offer_links, %i[source_id target_id], unique: true
  end
end
