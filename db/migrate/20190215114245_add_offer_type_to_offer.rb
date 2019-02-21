class AddOfferTypeToOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :offer_type, :string, null: true
  end
end
