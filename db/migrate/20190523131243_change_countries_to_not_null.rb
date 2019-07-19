class ChangeCountriesToNotNull < ActiveRecord::Migration[5.2]
  def up
    change_column :projects, :country_of_customer, :string, null: false
    change_column :projects, :country_of_collaboration, :string, null: false,
                  array: true, default: []
  end

  def down
    change_column :projects, :country_of_customer, :string, null: true
    change_column :projects, :country_of_collaboration, :string, null: true
  end
end
