# frozen_string_literal: true

class CreateDatasourceVocabularies < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_vocabularies do |t|
      t.belongs_to :datasource, index: true, foreign_key: true
      t.belongs_to :vocabulary, index: true, foreign_key: true
      t.string :vocabulary_type

      t.timestamps
    end
    add_index :datasource_vocabularies,
              %i[datasource_id vocabulary_id vocabulary_type],
              name: "index_datasources_vocabularies"
  end
end
