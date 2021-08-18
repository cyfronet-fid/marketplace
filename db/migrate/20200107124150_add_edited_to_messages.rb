# frozen_string_literal: true

class AddEditedToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :edited, :boolean, default: false
  end
end
