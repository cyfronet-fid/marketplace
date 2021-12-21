# frozen_string_literal: true

class ChangePlacesToGeographicalAvailabilities < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :places, :geographical_availabilities
    execute(<<~SQL)
      UPDATE services
      SET geographical_availabilities[1] =
        CASE geographical_availabilities[1]
          WHEN 'Europe' THEN 'EU'
          WHEN 'World' THEN 'WW'
          WHEN 'Worldwide' THEN 'WW'
        END
      SQL
  end
end
