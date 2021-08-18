# frozen_string_literal: true

class ChangeUniquenessOfNamesInCategoriesProvidersPlatformsAndResearchAreas < ActiveRecord::Migration[5.2]
  def change
    remove_index :categories, :name
    add_index :categories, :name, unique: true
    add_index :platforms, :name, unique: true
    add_index :providers, :name, unique: true
    add_index :research_areas, :name, unique: true
  end
end
