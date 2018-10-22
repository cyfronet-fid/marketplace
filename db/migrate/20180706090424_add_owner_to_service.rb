# frozen_string_literal: true

class AddOwnerToService < ActiveRecord::Migration[5.2]
  def change
    add_reference :services, :owner
    add_foreign_key :services, :users, column: :owner_id
  end
end
