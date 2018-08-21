class CreateServiceOpinions < ActiveRecord::Migration[5.2]
  def change
    create_table :service_opinions do |t|
      t.integer :rating, null: false
      t.text :opinion
      t.timestamp :created_at, null: false
      t.bigint "order_id"
      t.index ["order_id"], name: "index_service_opinions_on_order_id"
    end
  end
end
