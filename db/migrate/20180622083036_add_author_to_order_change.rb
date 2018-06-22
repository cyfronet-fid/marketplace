class AddAuthorToOrderChange < ActiveRecord::Migration[5.2]
  def change
    add_reference :order_changes, :author
    add_foreign_key :order_changes, :users, column: :author_id
  end
end
