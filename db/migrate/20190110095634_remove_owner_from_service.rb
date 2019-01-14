class RemoveOwnerFromService < ActiveRecord::Migration[5.2]
  def change
    remove_reference :services, :owner
  end
end
