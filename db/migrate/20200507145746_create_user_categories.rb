# frozen_string_literal: true

class CreateUserCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :user_categories do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.belongs_to :category, foreign_key: true, index: true

      t.timestamps
    end

    add_index :user_categories, %i[user_id category_id], unique: true
  end
end
