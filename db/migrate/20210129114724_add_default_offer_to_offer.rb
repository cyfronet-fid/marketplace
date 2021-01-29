class AddDefaultOfferToOffer < ActiveRecord::Migration[6.0]
  def change
    add_column :offers, :default, :boolean, default: false
  end
end
