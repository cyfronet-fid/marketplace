# frozen_string_literal: true

class RemoveV5Vocabularies < ActiveRecord::Migration[7.2]
  def up
    # V5 vocabulary models and lookup tables still back live associations, seeds,
    # offer creation, API facets, and backoffice forms. Slice A only removes them
    # from the V6 Provider Catalogue import and vocabulary-management surface.
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
