# frozen_string_literal: true

class CreateCatalogueVocabularies < ActiveRecord::Migration[6.1]
  def change
    create_table :catalogue_vocabularies do |t|
      t.belongs_to :catalogue, index: true, foreign_key: true
      t.belongs_to :vocabulary, index: true, foreign_key: true
      t.string :vocabulary_type

      t.timestamps
    end

    add_index :catalogue_vocabularies, %i[catalogue_id vocabulary_id], unique: true
  end
end
