# frozen_string_literal: true

class RemoveCatalogueFromServiceAndProvider < ActiveRecord::Migration[6.1]
  def change
    remove_column :services, :catalogue
    remove_column :providers, :catalogue
  end
end
