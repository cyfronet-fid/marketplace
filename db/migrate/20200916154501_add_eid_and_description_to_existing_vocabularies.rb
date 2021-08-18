# frozen_string_literal: true

class AddEidAndDescriptionToExistingVocabularies < ActiveRecord::Migration[6.0]
  def up
    add_column :categories, :eid, :string
    add_column :scientific_domains, :eid, :string
    add_column :scientific_domains, :description, :text
    add_column :platforms, :eid, :string

    change_column :vocabularies, :description, :text
    change_column :categories, :description, :text
  end

  def down
    remove_column :categories, :eid
    remove_column :scientific_domains, :eid
    remove_column :scientific_domains, :description
    remove_column :platforms, :eid

    change_column :vocabularies, :description, :string
    change_column :categories, :description, :string
  end
end
