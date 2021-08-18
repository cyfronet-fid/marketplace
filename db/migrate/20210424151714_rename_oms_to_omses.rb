# frozen_string_literal: true

class RenameOMSToOMSes < ActiveRecord::Migration[6.0]
  def change
    rename_table :oms, :omses
  end
end
