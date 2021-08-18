# frozen_string_literal: true

class RemoveMessageFromStatus < ActiveRecord::Migration[5.2]
  def change
    remove_column :statuses, :message, :boolean
  end
end
