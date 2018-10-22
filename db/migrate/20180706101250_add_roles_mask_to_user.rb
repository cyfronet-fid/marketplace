# frozen_string_literal: true

class AddRolesMaskToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :roles_mask, :integer
  end
end
