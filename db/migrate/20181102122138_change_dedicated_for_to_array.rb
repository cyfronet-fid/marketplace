class ChangeDedicatedForToArray < ActiveRecord::Migration[5.2]
  def up
    change_column :services, :dedicated_for, :text, using: "(string_to_array(dedicated_for, ','))", array: true
  end

  def down
    change_column :services, :dedicated_for, :text, null: false
  end
end
