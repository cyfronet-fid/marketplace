# frozen_string_literal: true

class CreateDatasourceScientificDomains < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_scientific_domains do |t|
      t.belongs_to :datasource, foreign_key: true, index: true
      t.belongs_to :scientific_domain, foreign_key: true, index: true

      t.timestamps
    end

    add_index :datasource_scientific_domains,
              %i[datasource_id scientific_domain_id],
              unique: true,
              name: "index_datasource_scientific_domains"
  end
end
