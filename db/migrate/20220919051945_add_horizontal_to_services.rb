# frozen_string_literal: true

class AddHorizontalToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :horizontal, :boolean, default: false, null: false
  end
end
