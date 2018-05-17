class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
