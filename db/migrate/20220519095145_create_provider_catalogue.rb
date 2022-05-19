# frozen_string_literal: true

class CreateProviderCatalogue < ActiveRecord::Migration[6.1]
  def change
    create_table :provider_catalogues do |t|
      t.belongs_to :provider, foreign_key: true, index: true
      t.belongs_to :catalogue, foreign_key: true, index: true

      t.timestamps
    end

    add_index :provider_catalogues, %i[provider_id catalogue_id], unique: true
  end
end
