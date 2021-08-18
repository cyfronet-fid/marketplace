# frozen_string_literal: true

class ChangeLanguagesToLanguageAvailability < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :languages, :language_availability
  end
end
