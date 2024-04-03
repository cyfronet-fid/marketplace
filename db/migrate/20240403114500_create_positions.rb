class CreatePositions < ActiveRecord::Migration[6.1]
  def change
    create_table :positions do |t|
      t.string :pid, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.references :contributor, null: false, foreign_key: true

      t.timestamps
    end
  end
end
