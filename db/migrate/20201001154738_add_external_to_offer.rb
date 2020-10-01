class AddExternalToOffer < ActiveRecord::Migration[6.0]
  def change
    add_column :offers, :external, :boolean, default: false
  end
end
