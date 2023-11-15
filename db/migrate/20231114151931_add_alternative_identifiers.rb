# frozen_string_literal: true

class AddAlternativeIdentifiers < ActiveRecord::Migration[6.1]
  def change
    create_table :alternative_identifiers do |t|
      t.string :identifier_type
      t.string :value
      t.timestamps
    end

    %i[provider service].each do |klazz|
      create_table :"#{klazz}_alternative_identifiers" do |t|
        t.belongs_to :"#{klazz}",
                     foreign_key: true,
                     index: {
                       name: "index_#{klazz}_alternative_id_on_#{klazz}_id",
                       unique: false
                     }
        t.belongs_to :alternative_identifier,
                     foreign_key: true,
                     index: {
                       name: "index_#{klazz}_alternative_id_on_alternative_id_id",
                       unique: false
                     }
        t.timestamps
      end
    end
  end
end
