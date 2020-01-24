class CreateHomePage < ActiveRecord::Migration[6.0]
  def change
    create_table :home_pages do |t|
      t.text :sections, array: true, default: []
    end
  end
end
