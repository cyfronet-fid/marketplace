# frozen_string_literal: true

class AddResourceOrganisationToProject < ActiveRecord::Migration[6.0]
  def up
    add_reference :services, :resource_organisation, foreign_key: { to_table: :providers }
    execute(<<~SQL)
        UPDATE services
        SET resource_organisation_id =
        (
          SELECT id
          FROM providers p
          WHERE p.name  LIKE 'not specified yet'
        )
      SQL
  end

  def down
    remove_column :services, :resource_organisation_id
  end
end
