# frozen_string_literal: true

class AddNewAssociationsToOffer < ActiveRecord::Migration[6.1]
  def change
    create_table :offer_vocabularies do |t|
      t.belongs_to :offer, foreign_key: true, index: true
      t.belongs_to :vocabulary, foreign_key: true, index: true

      t.timestamps
    end

    add_column :offers, :restrictions, :text
    add_column :offers, :offer_category_id, :integer, foreign_key: true
    add_column :offers, :offer_type_id, :integer, foreign_key: true
    add_column :offers, :offer_subtype_id, :integer, foreign_key: true

    add_index :offer_vocabularies, %i[offer_id vocabulary_id], unique: true
  end
end
