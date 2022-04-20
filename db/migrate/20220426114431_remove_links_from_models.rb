# frozen_string_literal: true

class RemoveLinksFromModels < ActiveRecord::Migration[6.1]
  def change
    remove_column :services, :use_cases_url
    remove_column :services, :multimedia
    remove_column :providers, :multimedia
  end
end
