class AddIidToOrderChange < ActiveRecord::Migration[5.2]
  def change
    add_column :order_changes, :iid, :integer, index: true
  end
end
