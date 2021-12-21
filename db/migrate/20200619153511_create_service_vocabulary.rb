# frozen_string_literal: true

class CreateServiceVocabulary < ActiveRecord::Migration[6.0]
  def change
    create_table :service_vocabularies do |t|
      t.belongs_to :service, index: true, foreign_key: true
      t.belongs_to :vocabulary, index: true, foreign_key: true
      t.string :vocabulary_type

      t.timestamps
    end
    add_index :service_vocabularies, %i[service_id vocabulary_id], unique: true
  end
end
