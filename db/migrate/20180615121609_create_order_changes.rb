class CreateOrderChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :order_changes do |t|
      t.string :status
      t.text :message
      t.belongs_to :order, null: false, index: true

      t.timestamps
    end
  end
end
