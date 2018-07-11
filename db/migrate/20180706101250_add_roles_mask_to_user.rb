class AddRolesMaskToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :roles_mask, :integer
  end
end
