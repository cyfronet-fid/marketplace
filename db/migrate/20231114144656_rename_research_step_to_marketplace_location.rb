# frozen_string_literal: true

class RenameResearchStepToMarketplaceLocation < ActiveRecord::Migration[6.1]
  def change
    execute(<<~SQL)
      DELETE FROM service_vocabularies
      WHERE vocabulary_type='Vocabulary::ResearchStep';
    SQL

    execute(<<~SQL)
      DELETE FROM vocabularies
      WHERE type='Vocabulary::ResearchStep';
    SQL
  end
end
