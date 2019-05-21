class AddCountriesToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :country_of_customer, :string
    add_column :projects, :country_of_collaboration, :string
    change_column_null :projects, :country_of_customer, "non-applicable"
    change_column_null :projects, :country_of_collaboration, "non-applicable"
  end

  def down
    remove_column :projects, :country_of_customer
    remove_column :projects, :country_of_collaboration
  end
end
