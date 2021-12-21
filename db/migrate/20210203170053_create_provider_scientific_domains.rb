# frozen_string_literal: true

class CreateProviderScientificDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :provider_scientific_domains do |t|
      t.belongs_to :provider, index: true, foreign_key: true
      t.belongs_to :scientific_domain, index: true, foreign_key: true

      t.timestamps
    end
    add_index :provider_scientific_domains,
              %i[provider_id scientific_domain_id],
              unique: true,
              name: "index_psd_on_provider_id_and_sd_id"
  end
end
