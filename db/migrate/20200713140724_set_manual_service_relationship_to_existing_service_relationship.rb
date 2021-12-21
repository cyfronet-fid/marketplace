# frozen_string_literal: true

class SetManualServiceRelationshipToExistingServiceRelationship < ActiveRecord::Migration[6.0]
  def change
    execute(<<~SQL)
      UPDATE service_relationships
      SET type = 'ManualServiceRelationship'
      SQL
  end
end
