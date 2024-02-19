# frozen_string_literal: true

class ChangeCatalogueDescriptionToText < ActiveRecord::Migration[6.1]
  def change
    change_column :catalogues, :description, :text, default: ""
  end
end
