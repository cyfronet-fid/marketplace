# frozen_string_literal: true

class AddUserSecretsToProjectItem < ActiveRecord::Migration[6.0]
  def change
    add_column :project_items, :user_secrets, :jsonb, default: {}, null: false
  end
end
