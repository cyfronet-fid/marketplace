class AddTaglineToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :tagline, :text
    change_column_null :services, :tagline, false
  end
end
