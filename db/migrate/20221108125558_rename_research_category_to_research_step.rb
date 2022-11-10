# frozen_string_literal: true

class RenameResearchCategoryToResearchStep < ActiveRecord::Migration[6.1]
  def change
    execute(<<~SQL)
      UPDATE vocabularies
      SET type='Vocabulary::ResearchStep'
      WHERE type='Vocabulary::ResearchCategory';
    SQL

    execute(<<~SQL)
      UPDATE service_vocabularies 
      SET vocabulary_type='Vocabulary::ResearchStep'
      WHERE vocabulary_type='Vocabulary::ResearchCategory';
    SQL

    execute(<<~SQL)
      UPDATE datasource_vocabularies 
      SET vocabulary_type='Vocabulary::ResearchStep'
      WHERE vocabulary_type='Vocabulary::ResearchCategory';
    SQL
  end
end
