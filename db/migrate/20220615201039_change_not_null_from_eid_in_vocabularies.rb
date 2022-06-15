# frozen_string_literal: true

class ChangeNotNullFromEidInVocabularies < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:vocabularies, :eid, true)
  end
end
