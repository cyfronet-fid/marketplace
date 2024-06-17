# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_04_12_153457) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alternative_identifiers", force: :cascade do |t|
    t.string "identifier_type"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bundle_categories", force: :cascade do |t|
    t.bigint "bundle_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id"], name: "index_bundle_categories_on_bundle_id"
    t.index ["category_id"], name: "index_bundle_categories_on_category_id"
  end

  create_table "bundle_offers", force: :cascade do |t|
    t.bigint "bundle_id", null: false
    t.bigint "offer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id", "offer_id"], name: "index_bundle_offers_on_bundle_id_and_offer_id", unique: true
    t.index ["bundle_id"], name: "index_bundle_offers_on_bundle_id"
    t.index ["offer_id"], name: "index_bundle_offers_on_offer_id"
  end

  create_table "bundle_scientific_domains", force: :cascade do |t|
    t.bigint "bundle_id", null: false
    t.bigint "scientific_domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id"], name: "index_bundle_scientific_domains_on_bundle_id"
    t.index ["scientific_domain_id"], name: "index_bundle_scientific_domains_on_scientific_domain_id"
  end

  create_table "bundle_target_users", force: :cascade do |t|
    t.bigint "bundle_id", null: false
    t.bigint "target_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id"], name: "index_bundle_target_users_on_bundle_id"
    t.index ["target_user_id"], name: "index_bundle_target_users_on_target_user_id"
  end

  create_table "bundle_vocabularies", force: :cascade do |t|
    t.bigint "bundle_id", null: false
    t.bigint "vocabulary_id", null: false
    t.string "vocabulary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bundle_id", "vocabulary_id", "vocabulary_type"], name: "index_bundles_vocabularies"
    t.index ["bundle_id"], name: "index_bundle_vocabularies_on_bundle_id"
    t.index ["vocabulary_id"], name: "index_bundle_vocabularies_on_vocabulary_id"
  end

  create_table "bundles", force: :cascade do |t|
    t.bigint "iid", null: false
    t.string "name", null: false
    t.string "capability_of_goal_suggestion"
    t.text "description", null: false
    t.string "order_type", null: false
    t.jsonb "parameters"
    t.bigint "main_offer_id", null: false
    t.bigint "service_id", null: false
    t.bigint "resource_organisation_id", null: false
    t.string "status", default: "published"
    t.boolean "related_training", default: false
    t.string "related_training_url"
    t.string "contact_email"
    t.string "helpdesk_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_items_count", default: 0, null: false
    t.integer "usage_counts_views", default: 0, null: false
    t.index ["iid"], name: "index_bundles_on_iid"
    t.index ["main_offer_id"], name: "index_bundles_on_main_offer_id"
    t.index ["resource_organisation_id"], name: "index_bundles_on_resource_organisation_id"
    t.index ["service_id", "iid"], name: "index_bundles_on_service_id_and_iid", unique: true
    t.index ["service_id"], name: "index_bundles_on_service_id"
  end

  create_table "catalogue_data_administrators", force: :cascade do |t|
    t.bigint "data_administrator_id"
    t.bigint "catalogue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id"], name: "index_catalogue_data_administrators_on_catalogue_id"
    t.index ["data_administrator_id"], name: "index_catalogue_data_administrators_on_data_administrator_id"
  end

  create_table "catalogue_scientific_domains", force: :cascade do |t|
    t.bigint "catalogue_id"
    t.bigint "scientific_domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id", "scientific_domain_id"], name: "index_cat_sds_on_catalogue_id_and_scientific_domain_id", unique: true
    t.index ["catalogue_id"], name: "index_catalogue_scientific_domains_on_catalogue_id"
    t.index ["scientific_domain_id"], name: "index_catalogue_scientific_domains_on_scientific_domain_id"
  end

  create_table "catalogue_sources", force: :cascade do |t|
    t.string "eid", null: false
    t.string "source_type", null: false
    t.bigint "catalogue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id"], name: "index_catalogue_sources_on_catalogue_id"
    t.index ["eid", "source_type", "catalogue_id"], name: "index_catalogue_sources_on_eid_and_source_type_and_catalogue_id", unique: true
  end

  create_table "catalogue_vocabularies", force: :cascade do |t|
    t.bigint "catalogue_id"
    t.bigint "vocabulary_id"
    t.string "vocabulary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id", "vocabulary_id"], name: "index_catalogue_vocabularies_on_catalogue_id_and_vocabulary_id", unique: true
    t.index ["catalogue_id"], name: "index_catalogue_vocabularies_on_catalogue_id"
    t.index ["vocabulary_id"], name: "index_catalogue_vocabularies_on_vocabulary_id"
  end

  create_table "catalogues", force: :cascade do |t|
    t.string "name", null: false
    t.string "pid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "synchronized_at", precision: nil
    t.string "abbreviation", default: ""
    t.string "website", default: ""
    t.boolean "legal_entity", default: false
    t.string "inclusion_criteria", default: ""
    t.string "validation_process", default: ""
    t.string "end_of_life", default: ""
    t.string "status", default: "published"
    t.text "description", default: ""
    t.string "tags", default: [], array: true
    t.string "structure_type", default: [], array: true
    t.string "street_name_and_number", default: ""
    t.string "postal_code", default: ""
    t.string "city", default: ""
    t.string "region", default: ""
    t.string "country", default: ""
    t.string "participating_countries", default: [], array: true
    t.string "affiliations", default: [], array: true
    t.integer "upstream_id"
    t.text "scope", default: ""
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "ancestry"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug"
    t.integer "ancestry_depth", default: 0
    t.string "eid"
    t.index ["ancestry"], name: "index_categories_on_ancestry"
    t.index ["description"], name: "index_categories_on_description"
    t.index ["name", "ancestry"], name: "index_categories_on_name_and_ancestry", unique: true
  end

  create_table "categorizations", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "category_id"
    t.boolean "main", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category_id"], name: "index_categorizations_on_category_id"
    t.index ["service_id"], name: "index_categorizations_on_service_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.string "phone"
    t.string "position"
    t.string "organisation"
    t.string "contactable_type"
    t.string "type"
    t.bigint "contactable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contactable_id"], name: "index_contacts_on_contactable_id"
    t.index ["id", "contactable_id", "contactable_type"], name: "index_contacts_on_id_and_contactable_id_and_contactable_type", unique: true
  end

  create_table "contributors", force: :cascade do |t|
    t.string "pid_type", null: false
    t.string "pid", null: false
    t.boolean "leader", null: false
    t.boolean "contact", null: false
    t.string "roles", default: [], array: true
    t.bigint "raid_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_project_id"], name: "index_contributors_on_raid_project_id"
  end

  create_table "data_administrators", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_data_administrators_on_email"
    t.index ["first_name"], name: "index_data_administrators_on_first_name"
    t.index ["last_name"], name: "index_data_administrators_on_last_name"
  end

  create_table "descriptions", force: :cascade do |t|
    t.text "text", null: false
    t.string "language"
    t.string "type", null: false
    t.string "description_type", null: false
    t.bigint "raid_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_project_id"], name: "index_descriptions_on_raid_project_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "action", null: false
    t.string "eventable_type"
    t.bigint "eventable_id", null: false
    t.jsonb "updates", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["eventable_type", "eventable_id"], name: "index_events_on_eventable_type_and_eventable_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "guidelines", force: :cascade do |t|
    t.string "title"
    t.string "eid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["eid"], name: "index_guidelines_on_eid", unique: true
  end

  create_table "help_items", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug"
    t.integer "position", default: 0, null: false
    t.bigint "help_section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["help_section_id"], name: "index_help_items_on_help_section_id"
  end

  create_table "help_sections", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lead_sections", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.string "template", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leads", force: :cascade do |t|
    t.string "header", null: false
    t.string "body", null: false
    t.string "url", null: false
    t.bigint "lead_section_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_section_id"], name: "index_leads_on_lead_section_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "type", null: false
    t.string "linkable_type"
    t.bigint "linkable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id", "linkable_id", "linkable_type"], name: "index_links_on_id_and_linkable_id_and_linkable_type", unique: true
    t.index ["linkable_id"], name: "index_links_on_linkable_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "author_id"
    t.text "message"
    t.integer "iid"
    t.string "messageable_type"
    t.bigint "messageable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "edited", default: false
    t.string "author_email"
    t.string "author_name"
    t.string "author_role", null: false
    t.string "scope", null: false
    t.string "author_uid"
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["author_role"], name: "index_messages_on_author_role"
    t.index ["messageable_type", "messageable_id"], name: "index_messages_on_messageable_type_and_messageable_id"
    t.index ["scope"], name: "index_messages_on_scope"
  end

  create_table "offer_links", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["source_id", "target_id"], name: "index_offer_links_on_source_id_and_target_id", unique: true
    t.index ["source_id"], name: "index_offer_links_on_source_id"
    t.index ["target_id"], name: "index_offer_links_on_target_id"
  end

  create_table "offer_vocabularies", force: :cascade do |t|
    t.bigint "offer_id"
    t.bigint "vocabulary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id", "vocabulary_id"], name: "index_offer_vocabularies_on_offer_id_and_vocabulary_id", unique: true
    t.index ["offer_id"], name: "index_offer_vocabularies_on_offer_id"
    t.index ["vocabulary_id"], name: "index_offer_vocabularies_on_vocabulary_id"
  end

  create_table "offers", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "iid", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "parameters", default: [], null: false
    t.boolean "voucherable", default: false, null: false
    t.string "status"
    t.string "order_type", null: false
    t.boolean "internal", default: false
    t.string "order_url", default: "", null: false
    t.boolean "default", default: false
    t.jsonb "oms_params"
    t.bigint "primary_oms_id"
    t.boolean "bundle_exclusive", default: false
    t.integer "project_items_count", default: 0, null: false
    t.integer "usage_counts_views", default: 0, null: false
    t.text "restrictions"
    t.integer "offer_category_id"
    t.integer "offer_type_id"
    t.integer "offer_subtype_id"
    t.index ["iid"], name: "index_offers_on_iid"
    t.index ["primary_oms_id"], name: "index_offers_on_primary_oms_id"
    t.index ["service_id", "iid"], name: "index_offers_on_service_id_and_iid", unique: true
    t.index ["service_id"], name: "index_offers_on_service_id"
  end

  create_table "oms_administrations", force: :cascade do |t|
    t.bigint "oms_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oms_id", "user_id"], name: "index_oms_administrations_on_oms_id_and_user_id", unique: true
    t.index ["oms_id"], name: "index_oms_administrations_on_oms_id"
    t.index ["user_id"], name: "index_oms_administrations_on_user_id"
  end

  create_table "oms_authorizations", force: :cascade do |t|
    t.bigint "oms_trigger_id", null: false
    t.string "type", null: false
    t.string "user"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oms_trigger_id"], name: "index_oms_authorizations_on_oms_trigger_id"
  end

  create_table "oms_providers", force: :cascade do |t|
    t.bigint "oms_id", null: false
    t.bigint "provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oms_id", "provider_id"], name: "index_oms_providers_on_oms_id_and_provider_id", unique: true
    t.index ["oms_id"], name: "index_oms_providers_on_oms_id"
    t.index ["provider_id"], name: "index_oms_providers_on_provider_id"
  end

  create_table "oms_triggers", force: :cascade do |t|
    t.bigint "oms_id", null: false
    t.string "url", null: false
    t.string "method", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oms_id"], name: "index_oms_triggers_on_oms_id"
  end

  create_table "omses", force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.jsonb "custom_params"
    t.boolean "default", default: false, null: false
    t.bigint "service_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default"], name: "index_omses_on_default"
    t.index ["service_id"], name: "index_omses_on_service_id"
    t.index ["type"], name: "index_omses_on_type"
  end

  create_table "persistent_identity_system_vocabularies", force: :cascade do |t|
    t.bigint "persistent_identity_system_id"
    t.bigint "vocabulary_id"
    t.string "vocabulary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["persistent_identity_system_id", "vocabulary_id"], name: "index_persistent_id_system_vocabularies"
    t.index ["persistent_identity_system_id"], name: "index_persistent_id_system"
    t.index ["vocabulary_id"], name: "index_persistent_id_system_on_vocabulary"
  end

  create_table "persistent_identity_systems", force: :cascade do |t|
    t.bigint "service_id", null: false
    t.bigint "entity_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type_id"], name: "index_persistent_identity_systems_on_entity_type_id"
    t.index ["id", "entity_type_id"], name: "index_persistent_identity_systems_on_id_and_entity_type_id"
    t.index ["service_id", "entity_type_id"], name: "index_persistent_id_systems"
    t.index ["service_id"], name: "index_persistent_identity_systems_on_service_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "eid"
    t.string "description"
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.jsonb "extras"
    t.index ["name"], name: "index_platforms_on_name", unique: true
  end

  create_table "positions", force: :cascade do |t|
    t.string "pid"
    t.date "start_date"
    t.date "end_date"
    t.string "positionable_type", null: false
    t.bigint "positionable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["positionable_type", "positionable_id"], name: "index_positions_on_positionable"
  end

  create_table "project_items", force: :cascade do |t|
    t.string "status_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "issue_id"
    t.integer "issue_status", default: 2, null: false
    t.bigint "project_id"
    t.bigint "offer_id"
    t.jsonb "properties", default: [], null: false
    t.boolean "request_voucher", default: false, null: false
    t.string "voucher_id", default: "", null: false
    t.integer "iid"
    t.string "name", null: false
    t.text "description", null: false
    t.string "order_type", null: false
    t.boolean "voucherable", default: false, null: false
    t.boolean "internal", default: false
    t.string "order_url", default: "", null: false
    t.string "status", default: "created", null: false
    t.jsonb "user_secrets", default: {}, null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.datetime "conversation_last_seen", precision: nil, null: false
    t.integer "bundle_id"
    t.index ["ancestry"], name: "index_project_items_on_ancestry"
    t.index ["offer_id"], name: "index_project_items_on_offer_id"
    t.index ["project_id"], name: "index_project_items_on_project_id"
  end

  create_table "project_research_products", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "research_product_id", null: false
    t.index ["project_id", "research_product_id"], name: "index_on_project_id_and_rp_id", unique: true
    t.index ["project_id"], name: "index_project_research_products_on_project_id"
    t.index ["research_product_id"], name: "index_project_research_products_on_research_product_id"
  end

  create_table "project_scientific_domains", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "scientific_domain_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["project_id", "scientific_domain_id"], name: "index_psd_on_service_id_and_sd_id", unique: true
    t.index ["project_id"], name: "index_project_scientific_domains_on_project_id"
    t.index ["scientific_domain_id"], name: "index_project_scientific_domains_on_scientific_domain_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.text "reason_for_access"
    t.string "customer_typology"
    t.string "user_group_name"
    t.string "project_name"
    t.string "project_website_url"
    t.string "company_name"
    t.string "company_website_url"
    t.string "country_of_origin"
    t.string "countries_of_partnership", default: [], array: true
    t.integer "issue_id"
    t.integer "issue_status", default: 2, null: false
    t.string "issue_key"
    t.text "additional_information"
    t.string "email"
    t.string "organization"
    t.string "department"
    t.string "webpage"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "conversation_last_seen", precision: nil, null: false
    t.index ["name", "user_id"], name: "index_projects_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "provider_alternative_identifiers", force: :cascade do |t|
    t.bigint "provider_id"
    t.bigint "alternative_identifier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alternative_identifier_id"], name: "index_provider_alternative_id_on_alternative_id_id"
    t.index ["provider_id"], name: "index_provider_alternative_id_on_provider_id"
  end

  create_table "provider_catalogues", force: :cascade do |t|
    t.bigint "provider_id"
    t.bigint "catalogue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id"], name: "index_provider_catalogues_on_catalogue_id"
    t.index ["provider_id", "catalogue_id"], name: "index_provider_catalogues_on_provider_id_and_catalogue_id", unique: true
    t.index ["provider_id"], name: "index_provider_catalogues_on_provider_id"
  end

  create_table "provider_data_administrators", force: :cascade do |t|
    t.bigint "data_administrator_id"
    t.bigint "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_administrator_id"], name: "index_provider_data_administrators_on_data_administrator_id"
    t.index ["provider_id"], name: "index_provider_data_administrators_on_provider_id"
  end

  create_table "provider_scientific_domains", force: :cascade do |t|
    t.bigint "provider_id"
    t.bigint "scientific_domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "scientific_domain_id"], name: "index_psd_on_provider_id_and_sd_id", unique: true
    t.index ["provider_id"], name: "index_provider_scientific_domains_on_provider_id"
    t.index ["scientific_domain_id"], name: "index_provider_scientific_domains_on_scientific_domain_id"
  end

  create_table "provider_sources", force: :cascade do |t|
    t.string "eid", null: false
    t.string "source_type", null: false
    t.bigint "provider_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "errored"
    t.index ["eid", "source_type", "provider_id"], name: "index_provider_sources_on_eid_and_source_type_and_provider_id", unique: true
    t.index ["provider_id"], name: "index_provider_sources_on_provider_id"
  end

  create_table "provider_vocabularies", force: :cascade do |t|
    t.bigint "provider_id"
    t.bigint "vocabulary_id"
    t.string "vocabulary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id", "vocabulary_id"], name: "index_provider_vocabularies_on_provider_id_and_vocabulary_id", unique: true
    t.index ["provider_id"], name: "index_provider_vocabularies_on_provider_id"
    t.index ["vocabulary_id"], name: "index_provider_vocabularies_on_vocabulary_id"
  end

  create_table "providers", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "pid"
    t.string "abbreviation"
    t.string "website"
    t.boolean "legal_entity"
    t.text "description"
    t.text "tagline"
    t.string "street_name_and_number"
    t.string "postal_code"
    t.string "city"
    t.string "region"
    t.string "country"
    t.string "certifications", default: [], array: true
    t.string "hosting_legal_entity_string"
    t.string "participating_countries", default: [], array: true
    t.string "affiliations", default: [], array: true
    t.string "national_roadmaps", default: [], array: true
    t.integer "upstream_id"
    t.datetime "synchronized_at", precision: nil
    t.string "status"
    t.integer "usage_counts_views", default: 0, null: false
    t.string "ppid"
  end

  create_table "raid_accesses", force: :cascade do |t|
    t.string "access_type", null: false
    t.date "embargo_expiry"
    t.string "statement_text"
    t.string "statement_lang"
    t.bigint "raid_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_project_id"], name: "index_raid_accesses_on_raid_project_id"
  end

  create_table "raid_organisations", force: :cascade do |t|
    t.string "pid", null: false
    t.bigint "raid_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.index ["raid_project_id"], name: "index_raid_organisations_on_raid_project_id"
  end

  create_table "raid_projects", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_raid_projects_on_user_id"
  end

  create_table "research_products", force: :cascade do |t|
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "title", null: false
    t.string "authors", default: [], array: true
    t.string "links", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "best_access_right"
    t.index ["resource_id", "resource_type"], name: "index_research_products_on_resource_id_and_resource_type", unique: true
  end

  create_table "rors", force: :cascade do |t|
    t.string "pid", null: false
    t.string "name", null: false
    t.string "acronyms", default: [], array: true
    t.string "aliases", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pid"], name: "index_rors_on_pid", unique: true
  end

  create_table "scientific_domains", force: :cascade do |t|
    t.text "name", null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.string "eid"
    t.text "description"
    t.index ["name", "ancestry"], name: "index_scientific_domains_on_name_and_ancestry", unique: true
  end

  create_table "service_alternative_identifiers", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "alternative_identifier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alternative_identifier_id"], name: "index_service_alternative_id_on_alternative_id_id"
    t.index ["service_id"], name: "index_service_alternative_id_on_service_id"
  end

  create_table "service_catalogues", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "catalogue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_id"], name: "index_service_catalogues_on_catalogue_id"
    t.index ["service_id", "catalogue_id"], name: "index_service_catalogues_on_service_id_and_catalogue_id", unique: true
    t.index ["service_id"], name: "index_service_catalogues_on_service_id"
  end

  create_table "service_guidelines", id: false, force: :cascade do |t|
    t.bigint "service_id", null: false
    t.bigint "guideline_id", null: false
    t.index ["guideline_id", "service_id"], name: "index_service_guidelines_on_guideline_id_and_service_id", unique: true
    t.index ["guideline_id"], name: "index_service_guidelines_on_guideline_id"
    t.index ["service_id"], name: "index_service_guidelines_on_service_id"
  end

  create_table "service_opinions", force: :cascade do |t|
    t.integer "service_rating", null: false
    t.text "opinion"
    t.bigint "project_item_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "order_rating", null: false
    t.index ["project_item_id"], name: "index_service_opinions_on_project_item_id"
  end

  create_table "service_providers", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "provider_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["provider_id"], name: "index_service_providers_on_provider_id"
    t.index ["service_id", "provider_id"], name: "index_service_providers_on_service_id_and_provider_id", unique: true
    t.index ["service_id"], name: "index_service_providers_on_service_id"
  end

  create_table "service_related_platforms", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "platform_id"
    t.index ["platform_id"], name: "index_service_related_platforms_on_platform_id"
    t.index ["service_id", "platform_id"], name: "index_service_related_platforms_on_service_id_and_platform_id", unique: true
    t.index ["service_id"], name: "index_service_related_platforms_on_service_id"
  end

  create_table "service_relationships", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.index ["source_id", "target_id", "type"], name: "index_service_relationships_on_source_id_and_target_id_and_type", unique: true
    t.index ["source_id"], name: "index_service_relationships_on_source_id"
    t.index ["target_id"], name: "index_service_relationships_on_target_id"
  end

  create_table "service_scientific_domains", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "scientific_domain_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["scientific_domain_id"], name: "index_service_scientific_domains_on_scientific_domain_id"
    t.index ["service_id", "scientific_domain_id"], name: "index_ssd_on_service_id_and_sd_id", unique: true
    t.index ["service_id"], name: "index_service_scientific_domains_on_service_id"
  end

  create_table "service_sources", force: :cascade do |t|
    t.string "eid", null: false
    t.string "source_type", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "errored"
    t.index ["eid", "source_type", "service_id"], name: "index_service_sources_on_eid_and_source_type_and_service_id", unique: true
    t.index ["service_id"], name: "index_service_sources_on_service_id"
  end

  create_table "service_target_users", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "target_user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["service_id", "target_user_id"], name: "index_service_target_users_on_service_id_and_target_user_id", unique: true
    t.index ["service_id"], name: "index_service_target_users_on_service_id"
    t.index ["target_user_id"], name: "index_service_target_users_on_target_user_id"
  end

  create_table "service_user_relationships", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["service_id"], name: "index_service_user_relationships_on_service_id"
    t.index ["user_id"], name: "index_service_user_relationships_on_user_id"
  end

  create_table "service_vocabularies", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "vocabulary_id"
    t.string "vocabulary_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "vocabulary_id"], name: "index_service_vocabularies_on_service_id_and_vocabulary_id", unique: true
    t.index ["service_id"], name: "index_service_vocabularies_on_service_id"
    t.index ["vocabulary_id"], name: "index_service_vocabularies_on_vocabulary_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "tagline", null: false
    t.decimal "rating", precision: 2, scale: 1, default: "0.0", null: false
    t.bigint "provider_id"
    t.integer "service_opinion_count", default: 0
    t.string "geographical_availabilities", default: [], array: true
    t.string "language_availability", default: [], array: true
    t.string "dedicated_for", array: true
    t.string "terms_of_use_url"
    t.string "access_policies_url"
    t.string "resource_level_url"
    t.string "webpage_url"
    t.string "manual_url"
    t.string "helpdesk_url"
    t.string "training_information_url"
    t.string "restrictions"
    t.integer "offers_count", default: 0
    t.text "activate_message"
    t.string "slug"
    t.string "order_type", null: false
    t.string "status"
    t.integer "upstream_id"
    t.string "helpdesk_email", default: ""
    t.integer "project_items_count", default: 0, null: false
    t.string "version"
    t.float "popularity_ratio"
    t.bigint "resource_organisation_id", null: false
    t.string "status_monitoring_url"
    t.string "maintenance_url"
    t.string "order_url", default: "", null: false
    t.string "payment_model_url"
    t.string "pricing_url"
    t.string "security_contact_email", default: "", null: false
    t.string "resource_geographic_locations", default: [], array: true
    t.string "certifications", default: [], array: true
    t.string "standards", default: [], array: true
    t.string "open_source_technologies", default: [], array: true
    t.text "changelog", default: [], array: true
    t.string "grant_project_names", default: [], array: true
    t.string "privacy_policy_url"
    t.datetime "last_update", precision: nil
    t.string "related_platforms", default: [], array: true
    t.datetime "synchronized_at", precision: nil
    t.string "pid"
    t.string "abbreviation"
    t.boolean "horizontal", default: false, null: false
    t.float "availability_cache"
    t.float "reliability_cache"
    t.string "submission_policy_url"
    t.string "preservation_policy_url"
    t.bigint "jurisdiction_id"
    t.bigint "datasource_classification_id"
    t.boolean "version_control"
    t.boolean "thematic", default: false
    t.string "type", default: "Service"
    t.integer "bundles_count", default: 0, null: false
    t.integer "usage_counts_views", default: 0, null: false
    t.string "ppid"
    t.string "datasource_id"
    t.boolean "harvestable", default: false
    t.index ["name"], name: "index_services_on_name"
    t.index ["pid"], name: "index_services_on_pid"
    t.index ["provider_id"], name: "index_services_on_provider_id"
    t.index ["resource_organisation_id"], name: "index_services_on_resource_organisation_id"
  end

  create_table "statuses", force: :cascade do |t|
    t.bigint "author_id"
    t.string "status_type"
    t.string "status_holder_type"
    t.bigint "status_holder_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "status", null: false
    t.index ["author_id"], name: "index_statuses_on_author_id"
    t.index ["status_holder_type", "status_holder_id"], name: "index_statuses_on_status_holder_type_and_status_holder_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "target_users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "description"
    t.text "eid"
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.index ["ancestry"], name: "index_target_users_on_ancestry"
  end

  create_table "titles", force: :cascade do |t|
    t.string "text", null: false
    t.string "language"
    t.string "type", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.bigint "raid_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title_type"
    t.index ["raid_project_id"], name: "index_titles_on_raid_project_id"
  end

  create_table "tour_feedbacks", force: :cascade do |t|
    t.string "controller_name"
    t.string "action_name"
    t.string "tour_name"
    t.bigint "user_id"
    t.string "email"
    t.json "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_name"], name: "index_tour_feedbacks_on_action_name"
    t.index ["controller_name"], name: "index_tour_feedbacks_on_controller_name"
    t.index ["email"], name: "index_tour_feedbacks_on_email"
    t.index ["tour_name"], name: "index_tour_feedbacks_on_tour_name"
    t.index ["user_id"], name: "index_tour_feedbacks_on_user_id"
  end

  create_table "tour_histories", force: :cascade do |t|
    t.string "controller_name"
    t.string "action_name"
    t.string "tour_name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tour_histories_on_created_at"
    t.index ["updated_at"], name: "index_tour_histories_on_updated_at"
    t.index ["user_id"], name: "index_tour_histories_on_user_id"
  end

  create_table "user_categories", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_user_categories_on_category_id"
    t.index ["user_id", "category_id"], name: "index_user_categories_on_user_id_and_category_id", unique: true
    t.index ["user_id"], name: "index_user_categories_on_user_id"
  end

  create_table "user_scientific_domains", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "scientific_domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scientific_domain_id"], name: "index_user_scientific_domains_on_scientific_domain_id"
    t.index ["user_id", "scientific_domain_id"], name: "index_usd_on_service_id_and_sd_id", unique: true
    t.index ["user_id"], name: "index_user_scientific_domains_on_user_id"
  end

  create_table "user_services", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "user_id"], name: "index_user_services_on_service_id_and_user_id", unique: true
    t.index ["service_id"], name: "index_user_services_on_service_id"
    t.index ["user_id"], name: "index_user_services_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "uid", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "roles_mask"
    t.integer "owned_services_count", default: 0, null: false
    t.boolean "categories_updates", default: false, null: false
    t.boolean "scientific_domains_updates", default: false, null: false
    t.boolean "show_welcome_popup", default: false, null: false
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email"
  end

  create_table "vocabularies", force: :cascade do |t|
    t.string "eid"
    t.string "name", null: false
    t.text "description"
    t.string "type", null: false
    t.string "ancestry"
    t.integer "ancestry_depth", default: 0
    t.jsonb "extras"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_vocabularies_on_ancestry"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalogue_scientific_domains", "catalogues"
  add_foreign_key "catalogue_scientific_domains", "scientific_domains"
  add_foreign_key "catalogue_vocabularies", "catalogues"
  add_foreign_key "catalogue_vocabularies", "vocabularies"
  add_foreign_key "catalogues", "catalogue_sources", column: "upstream_id", on_delete: :nullify
  add_foreign_key "contributors", "raid_projects"
  add_foreign_key "descriptions", "raid_projects"
  add_foreign_key "offer_links", "offers", column: "source_id"
  add_foreign_key "offer_links", "offers", column: "target_id"
  add_foreign_key "offer_vocabularies", "offers"
  add_foreign_key "offer_vocabularies", "vocabularies"
  add_foreign_key "offers", "omses", column: "primary_oms_id"
  add_foreign_key "oms_administrations", "omses"
  add_foreign_key "oms_administrations", "users"
  add_foreign_key "oms_authorizations", "oms_triggers"
  add_foreign_key "oms_providers", "omses"
  add_foreign_key "oms_providers", "providers"
  add_foreign_key "oms_triggers", "omses"
  add_foreign_key "omses", "services"
  add_foreign_key "persistent_identity_systems", "services"
  add_foreign_key "project_items", "bundles", on_delete: :nullify
  add_foreign_key "project_items", "offers"
  add_foreign_key "project_items", "projects"
  add_foreign_key "project_scientific_domains", "projects"
  add_foreign_key "project_scientific_domains", "scientific_domains"
  add_foreign_key "provider_alternative_identifiers", "alternative_identifiers"
  add_foreign_key "provider_alternative_identifiers", "providers"
  add_foreign_key "provider_catalogues", "catalogues"
  add_foreign_key "provider_catalogues", "providers"
  add_foreign_key "provider_scientific_domains", "providers"
  add_foreign_key "provider_scientific_domains", "scientific_domains"
  add_foreign_key "provider_vocabularies", "providers"
  add_foreign_key "provider_vocabularies", "vocabularies"
  add_foreign_key "providers", "provider_sources", column: "upstream_id", on_delete: :nullify
  add_foreign_key "raid_accesses", "raid_projects"
  add_foreign_key "raid_organisations", "raid_projects"
  add_foreign_key "raid_projects", "users"
  add_foreign_key "service_alternative_identifiers", "alternative_identifiers"
  add_foreign_key "service_alternative_identifiers", "services"
  add_foreign_key "service_catalogues", "catalogues"
  add_foreign_key "service_catalogues", "services"
  add_foreign_key "service_providers", "providers"
  add_foreign_key "service_providers", "services"
  add_foreign_key "service_related_platforms", "platforms"
  add_foreign_key "service_related_platforms", "services"
  add_foreign_key "service_relationships", "services", column: "source_id"
  add_foreign_key "service_relationships", "services", column: "target_id"
  add_foreign_key "service_scientific_domains", "scientific_domains"
  add_foreign_key "service_scientific_domains", "services"
  add_foreign_key "service_target_users", "services"
  add_foreign_key "service_target_users", "target_users"
  add_foreign_key "service_user_relationships", "services"
  add_foreign_key "service_user_relationships", "users"
  add_foreign_key "service_vocabularies", "services"
  add_foreign_key "service_vocabularies", "vocabularies"
  add_foreign_key "services", "providers"
  add_foreign_key "services", "providers", column: "resource_organisation_id"
  add_foreign_key "services", "service_sources", column: "upstream_id", on_delete: :nullify
  add_foreign_key "titles", "raid_projects"
  add_foreign_key "tour_feedbacks", "users"
  add_foreign_key "tour_histories", "users"
  add_foreign_key "user_categories", "categories"
  add_foreign_key "user_categories", "users"
  add_foreign_key "user_scientific_domains", "scientific_domains"
  add_foreign_key "user_scientific_domains", "users"
  add_foreign_key "user_services", "services"
  add_foreign_key "user_services", "users"
end
