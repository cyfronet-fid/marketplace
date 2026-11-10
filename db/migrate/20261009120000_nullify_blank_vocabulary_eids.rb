# frozen_string_literal: true

class NullifyBlankVocabularyEids < ActiveRecord::Migration[7.2]
  # Backoffice forms saved an empty eid input as "", which leaked into the catalogue API.
  # Raw SQL on purpose: models normalize eid, so a "" lookup through them would match NULL only.
  TABLES = %i[target_users vocabularies categories scientific_domains].freeze

  def up
    TABLES.each { |table| execute("UPDATE #{table} SET eid = NULL WHERE BTRIM(eid) = ''") }
  end

  def down
    # Blank and missing eids mean the same thing, nothing to restore.
  end
end
