# frozen_string_literal: true

class AddAuthorizationToTriggers < ActiveRecord::Migration[6.0]
  def change
    create_table :oms_authorizations do |t|
      t.belongs_to :oms_trigger, null: false, foreign_key: true
      t.string :type, null: false

      t.string :user
      t.string :password

      t.timestamps null: false
    end
  end
end
