# frozen_string_literal: true

class CreateProviderVocabulary < ActiveRecord::Migration[6.0]
  def change
    create_table :provider_vocabularies do |t|
      t.belongs_to :provider, index: true, foreign_key: true
      t.belongs_to :vocabulary, index: true, foreign_key: true
      t.string :vocabulary_type

      t.timestamps
    end
    add_index :provider_vocabularies, %i[provider_id vocabulary_id], unique: true
  end
end
