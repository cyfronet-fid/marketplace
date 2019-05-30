class AddCountriesToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :country_of_customer, :string
    add_column :projects, :country_of_collaboration, :string, array: true, default: []
  end

  def down
    remove_column :projects, :country_of_customer
    remove_column :projects, :country_of_collaboration
  end
end
