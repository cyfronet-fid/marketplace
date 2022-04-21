# frozen_string_literal: true

class RemoveUniqueFromNameInProviders < ActiveRecord::Migration[6.1]
  def change
    remove_index :providers, :name, unique: true
  end
end
