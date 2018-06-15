# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :status, null: false
      t.belongs_to :service, null: false, index: true
      t.belongs_to :user, null: false, index: true

      t.timestamps
    end
  end
end
