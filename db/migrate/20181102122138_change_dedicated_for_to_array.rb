class ChangeDedicatedForToArray < ActiveRecord::Migration[5.2]
  def change
    change_column :services, :dedicated_for, :text, using: "(string_to_array(dedicated_for, ','))", array: true, null: false
  end
end
