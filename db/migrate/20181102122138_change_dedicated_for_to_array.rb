# frozen_string_literal: true

class ChangeDedicatedForToArray < ActiveRecord::Migration[5.2]
  def up
    change_column :services, :dedicated_for, :string, using: "(string_to_array(dedicated_for, ','))", array: true
  end

  def down
    change_column :services, :dedicated_for, :string, null: true
  end
end
