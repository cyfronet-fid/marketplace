class AddTaglineToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :tagline, :text, null: false
  end
end
