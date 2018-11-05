class CreateServiceProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :service_providers do |t|
      t.belongs_to :service, foreign_key: true, index: true
      t.belongs_to :provider, foreign_key: true, index: true

      t.timestamps
    end

    add_index :service_providers, [:service_id, :provider_id], unique: true
  end
end
