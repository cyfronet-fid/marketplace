# frozen_string_literal: true

class CreateServiceUserRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :service_user_relationships do |t|
      t.belongs_to :service, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true

      t.timestamps
    end
  end
end
