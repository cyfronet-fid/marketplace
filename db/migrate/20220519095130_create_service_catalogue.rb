# frozen_string_literal: true

class CreateServiceCatalogue < ActiveRecord::Migration[6.1]
  def change
    create_table :service_catalogues do |t|
      t.belongs_to :service, foreign_key: true, index: true
      t.belongs_to :catalogue, foreign_key: true, index: true

      t.timestamps
    end

    add_index :service_catalogues, %i[service_id catalogue_id], unique: true
  end
end
