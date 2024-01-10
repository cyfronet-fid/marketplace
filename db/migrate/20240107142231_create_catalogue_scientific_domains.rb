# frozen_string_literal: true

class CreateCatalogueScientificDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :catalogue_scientific_domains do |t|
      t.belongs_to :catalogue, index: true, foreign_key: true
      t.belongs_to :scientific_domain, index: true, foreign_key: true

      t.timestamps
    end

    add_index :catalogue_scientific_domains,
              %i[catalogue_id scientific_domain_id],
              unique: true,
              name: "index_cat_sds_on_catalogue_id_and_scientific_domain_id"
  end
end
