# frozen_string_literal: true
class CreateDeployableServiceScientificDomains < ActiveRecord::Migration[7.2]
  def change
    create_table :deployable_service_scientific_domains do |t|
      t.references :deployable_service, null: false, foreign_key: true
      t.references :scientific_domain, null: false, foreign_key: true

      t.timestamps

      t.index %i[deployable_service_id scientific_domain_id],
              name: "index_ds_sci_domains_on_ds_id_and_sci_domain_id",
              unique: true
    end
  end
end
