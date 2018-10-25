class AddOffersCount < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :offers_count, :integer, default: 0
  end
end
