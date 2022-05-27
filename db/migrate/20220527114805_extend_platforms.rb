# frozen_string_literal: true

class ExtendPlatforms < ActiveRecord::Migration[6.1]
  def change
    add_column :platforms, :description, :string
    add_column :platforms, :ancestry, :string, index: true
    add_column :platforms, :ancestry_depth, :integer, default: 0
    add_column :platforms, :extras, :jsonb
  end
end
