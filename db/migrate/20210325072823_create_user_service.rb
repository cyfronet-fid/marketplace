# frozen_string_literal: true

class CreateUserService < ActiveRecord::Migration[6.0]
  def change
    create_table :user_services do |t|
      t.belongs_to :service, foreign_key: true, index: true
      t.belongs_to :user, foreign_key: true, index: true

      t.timestamps
    end

    add_index :user_services, %i[service_id user_id], unique: true
  end
end
