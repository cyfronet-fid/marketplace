class AddPidToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :pid, :string
  end
end
