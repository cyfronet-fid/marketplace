# frozen_string_literal: true

class ChangeServiceTitleToName < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :title, :name
  end
end
