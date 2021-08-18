# frozen_string_literal: true

class CreateProviderDataAdministrators < ActiveRecord::Migration[6.0]
  def change
    create_table :provider_data_administrators do |t|
      t.belongs_to :data_administrator, index: true
      t.belongs_to :provider, index: true

      t.timestamps
    end
  end
end
