# frozen_string_literal: true

class AddSlugToCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :slug, :string, unique: true
  end
end
