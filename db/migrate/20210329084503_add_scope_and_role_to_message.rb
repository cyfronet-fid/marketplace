# frozen_string_literal: true

class AddScopeAndRoleToMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :author_email, :string
    add_column :messages, :author_name, :string
    add_column :messages, :author_role, :string
    add_column :messages, :scope, :string

    exec_update "UPDATE messages SET author_role = 'provider' WHERE author_id IS NULL"
    exec_update "UPDATE messages SET author_role = 'user' WHERE author_id IS NOT NULL"
    exec_update "UPDATE messages SET scope = 'public'"

    change_column_null :messages, :author_role, false
    change_column_null :messages, :scope, false

    add_index :messages, :author_role
    add_index :messages, :scope
  end
end
