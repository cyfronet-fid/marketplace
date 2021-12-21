# frozen_string_literal: true

class ChangeLanguagesTypeToArray < ActiveRecord::Migration[6.0]
  def change
    change_column :services, :languages, :string, array: true, default: [], using: "(string_to_array(languages, ','))"
  end
end
