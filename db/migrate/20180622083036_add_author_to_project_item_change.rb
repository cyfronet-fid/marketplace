# frozen_string_literal: true

class AddAuthorToProjectItemChange < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_item_changes, :author
    add_foreign_key :project_item_changes, :users, column: :author_id
  end
end
