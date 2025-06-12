# frozen_string_literal: true

class ChangeProviderNameToString < ActiveRecord::Migration[7.2]
  def change
    change_column :providers, :name, :string
  end
end
