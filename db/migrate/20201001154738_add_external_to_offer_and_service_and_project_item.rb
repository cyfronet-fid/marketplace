class AddExternalToOfferAndServiceAndProjectItem < ActiveRecord::Migration[6.0]
  def change
    add_column :offers, :external, :boolean, default: false
    add_column :services, :external, :boolean, default: false
    add_column :project_items, :external, :boolean, default: false
  end
end
