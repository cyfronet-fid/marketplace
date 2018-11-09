class AddParametersToOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :parameters, :jsonb
  end
end
