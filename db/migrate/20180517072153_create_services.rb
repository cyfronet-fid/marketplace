class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :title, index: true
      t.text :description, index: true

      t.timestamps
    end
  end
end
