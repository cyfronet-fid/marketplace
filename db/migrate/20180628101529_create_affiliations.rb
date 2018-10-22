# frozen_string_literal: true

class CreateAffiliations < ActiveRecord::Migration[5.2]
  def change
    create_table :affiliations do |t|
      t.integer :iid, null: false, index: true
      t.string :organization, null: false
      t.string :department
      t.string :email, null: false
      t.string :phone
      t.string :webpage, null: false
      t.string :token, unique: true, index: true
      t.string :status, null: false, default: "created"
      t.string :supervisor
      t.string :supervisor_profile
      t.belongs_to :user, null: false, index: true

      t.timestamps
    end
  end
end
