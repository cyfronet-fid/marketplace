class RemoveExternalFromServiceOfferAndProjectItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :services, :external, :string
    remove_column :offers, :external, :string
    remove_column :project_items, :external, :string
  end
end
