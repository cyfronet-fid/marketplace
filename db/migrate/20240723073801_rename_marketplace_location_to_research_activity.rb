# frozen_string_literal: true
class RenameMarketplaceLocationToResearchActivity < ActiveRecord::Migration[7.1]
  execute(<<~SQL)
  UPDATE service_vocabularies
  SET vocabulary_type = 'Vocabulary::ResearchActivity'
  WHERE vocabulary_type = 'Vocabulary::MarketplaceLocation';
SQL

  execute(<<~SQL)
  UPDATE bundle_vocabularies
  SET vocabulary_type = 'Vocabulary::ResearchActivity'
  WHERE vocabulary_type = 'Vocabulary::MarketplaceLocation';
SQL

  execute(<<~SQL)
  UPDATE vocabularies
  SET type = 'Vocabulary::ResearchActivity'
  WHERE type = 'Vocabulary::MarketplaceLocation';
SQL
end
