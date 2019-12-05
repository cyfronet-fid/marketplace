class RemoveDescriptionIndexFromService < ActiveRecord::Migration[5.2]
  def change
    remove_index :services, :description
  end
end
