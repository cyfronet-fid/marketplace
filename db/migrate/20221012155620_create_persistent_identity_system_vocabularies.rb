# frozen_string_literal: true

class CreatePersistentIdentitySystemVocabularies < ActiveRecord::Migration[6.1]
  def change
    create_table :persistent_identity_system_vocabularies do |t|
      t.belongs_to :persistent_identity_system, index: { name: "index_persistent_id_system" }
      t.belongs_to :vocabulary, index: { name: "index_persistent_id_system_on_vocabulary" }
      t.string :vocabulary_type

      t.timestamps
    end
    add_index :persistent_identity_system_vocabularies,
              %i[persistent_identity_system_id vocabulary_id],
              name: "index_persistent_id_system_vocabularies"
  end
end
