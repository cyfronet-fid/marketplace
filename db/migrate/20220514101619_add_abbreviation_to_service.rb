# frozen_string_literal: true

class AddAbbreviationToService < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :abbreviation, :string
  end
end
