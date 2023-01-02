# frozen_string_literal: true

class CreateBundles < ActiveRecord::Migration[6.1]
  def change
    create_table :bundles do |t|
      t.bigint :iid, null: false, index: true
      t.string :name, null: false
      t.string :capability_of_goal_suggestion
      t.text :description, null: false
      t.string :order_type, null: false
      t.jsonb :parameters
      t.belongs_to :main_offer, null: false, index: true
      t.belongs_to :service, null: false, index: true
      t.belongs_to :resource_organisation, null: false, index: true
      t.string :status, default: "published"
      t.boolean :related_training, default: false
      t.string :related_training_url
      t.string :contact_email
      t.string :helpdesk_url, null: false

      t.timestamps
    end

    create_table :bundle_offers do |t|
      t.belongs_to :bundle, null: false, index: true
      t.belongs_to :offer, null: false, index: true

      t.timestamps
    end

    create_table :bundle_categories do |t|
      t.belongs_to :bundle, null: false, index: true
      t.belongs_to :category, null: false, index: true

      t.timestamps
    end

    create_table :bundle_scientific_domains do |t|
      t.belongs_to :bundle, null: false, index: true
      t.belongs_to :scientific_domain, null: false, index: true

      t.timestamps
    end

    create_table :bundle_vocabularies do |t|
      t.belongs_to :bundle, null: false, index: true
      t.belongs_to :vocabulary, null: false, index: true
      t.string :vocabulary_type

      t.timestamps
    end

    create_table :bundle_target_users do |t|
      t.belongs_to :bundle, null: false, index: true
      t.belongs_to :target_user, null: false, index: true

      t.timestamps
    end

    add_index :bundles, %i[service_id iid], unique: true
    add_index :bundle_vocabularies, %i[bundle_id vocabulary_id vocabulary_type], name: "index_bundles_vocabularies"
  end
end
