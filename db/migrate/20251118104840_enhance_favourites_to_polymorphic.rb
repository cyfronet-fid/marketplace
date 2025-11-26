# frozen_string_literal: true

class EnhanceFavouritesToPolymorphic < ActiveRecord::Migration[7.2]
  def change
    rename_table :user_services, :user_favourites
    add_column :user_favourites, :favoritable_type, :string
    rename_column :user_favourites, :service_id, :favoritable_id

    execute(<<~SQL)
        UPDATE user_favourites
        SET favoritable_type = 'Service'
      SQL

    add_index :user_favourites, %i[user_id favoritable_type favoritable_id], unique: true
  end
end
