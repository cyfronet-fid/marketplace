class ChangeCategoryNameUniqScope < ActiveRecord::Migration[5.2]
  def change
    remove_index :categories, :name
    add_index :categories, [:name, :ancestry], unique: true
  end
end
