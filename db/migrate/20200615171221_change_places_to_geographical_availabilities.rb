class ChangePlacesToGeographicalAvailabilities < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :places, :geographical_availabilities
  end
end
