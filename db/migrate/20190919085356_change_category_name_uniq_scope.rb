# frozen_string_literal: true

class ChangeCategoryNameUniqScope < ActiveRecord::Migration[5.2]
  def change
    remove_index :categories, :name
    add_index :categories, %i[name ancestry], unique: true
  end
end
