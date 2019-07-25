class AddCountriesToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :country_of_origin, :string
    add_column :projects, :countries_of_partnership, :string, array: true, default: []
  end
end
