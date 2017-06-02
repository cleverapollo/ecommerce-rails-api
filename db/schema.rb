# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170602072123) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "dblink"
  enable_extension "intarray"
  enable_extension "uuid-ossp"

  create_table "actions", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",          limit: 8,                 null: false
    t.integer  "item_id",          limit: 8,                 null: false
    t.integer  "view_count",                   default: 0,   null: false
    t.datetime "view_date"
    t.integer  "cart_count",                   default: 0,   null: false
    t.datetime "cart_date"
    t.integer  "purchase_count",               default: 0,   null: false
    t.datetime "purchase_date"
    t.float    "rating",                       default: 0.0
    t.integer  "shop_id",                                    null: false
    t.integer  "timestamp",                    default: 0,   null: false
    t.string   "recommended_by",   limit: 255
    t.integer  "last_action",      limit: 2,   default: 1,   null: false
    t.integer  "rate_count",                   default: 0,   null: false
    t.datetime "rate_date"
    t.integer  "last_user_rating"
    t.datetime "recommended_at"
  end

  add_index "actions", ["item_id"], name: "index_actions_on_item_id", using: :btree
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_purchases", where: "(purchase_count > 0)", using: :btree
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_rating", using: :btree
  add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", using: :btree
  add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", using: :btree
  add_index "actions", ["user_id", "item_id"], name: "index_actions_on_user_id_and_item_id", unique: true, using: :btree

  create_table "audience_segment_statistics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "overall",               default: 0, null: false
    t.integer "activity_a",            default: 0, null: false
    t.integer "activity_b",            default: 0, null: false
    t.integer "activity_c",            default: 0, null: false
    t.date    "recalculated_at",                   null: false
    t.integer "triggers_overall",      default: 0, null: false
    t.integer "triggers_activity_a",   default: 0, null: false
    t.integer "triggers_activity_b",   default: 0, null: false
    t.integer "triggers_activity_c",   default: 0, null: false
    t.integer "digests_overall",       default: 0, null: false
    t.integer "digests_activity_a",    default: 0, null: false
    t.integer "digests_activity_b",    default: 0, null: false
    t.integer "digests_activity_c",    default: 0, null: false
    t.integer "with_email",            default: 0, null: false
    t.integer "web_push_overall",      default: 0, null: false
    t.integer "with_email_activity_a", default: 0, null: false
    t.integer "with_email_activity_b", default: 0, null: false
    t.integer "with_email_activity_c", default: 0, null: false
    t.integer "web_push_activity_a",   default: 0, null: false
    t.integer "web_push_activity_b",   default: 0, null: false
    t.integer "web_push_activity_c",   default: 0, null: false
  end

  add_index "audience_segment_statistics", ["shop_id"], name: "index_audience_segment_statistics_on_shop_id", unique: true, using: :btree

  create_table "beacon_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",         limit: 8
    t.integer  "session_id",      limit: 8
    t.text     "params",                                      null: false
    t.boolean  "notified",                    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "deal_id",         limit: 255
    t.boolean  "tracked",                     default: false, null: false
    t.integer  "beacon_offer_id"
  end

  create_table "brand_campaign_shops", force: :cascade do |t|
    t.integer  "shop_id"
    t.datetime "last_event_at"
    t.integer  "brand_campaign_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "brand_campaign_shops", ["brand_campaign_id"], name: "index_brand_campaign_shops_on_brand_campaign_id", using: :btree
  add_index "brand_campaign_shops", ["shop_id"], name: "index_brand_campaign_shops_on_shop_id", using: :btree

  create_table "catalog_import_logs", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "filesize",   default: 0,     null: false
    t.integer  "total",      default: 0,     null: false
    t.integer  "available",  default: 0,     null: false
    t.integer  "widgetable", default: 0,     null: false
    t.integer  "categories", default: 0,     null: false
    t.string   "message"
    t.boolean  "success",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "client_carts", id: :bigserial, force: :cascade do |t|
    t.integer "user_id", limit: 8, null: false
    t.integer "shop_id",           null: false
    t.jsonb   "items"
    t.date    "date"
  end

  add_index "client_carts", ["date"], name: "index_client_carts_on_date", using: :btree
  add_index "client_carts", ["shop_id", "user_id"], name: "index_client_carts_on_shop_id_and_user_id", unique: true, using: :btree
  add_index "client_carts", ["shop_id"], name: "index_client_carts_on_shop_id", using: :btree

  create_table "client_errors", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "exception_class",   limit: 255,                 null: false
    t.text     "exception_message",                             null: false
    t.text     "params",                                        null: false
    t.boolean  "resolved",                      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referer",           limit: 255
  end

  add_index "client_errors", ["shop_id"], name: "index_client_errors_on_shop_id", where: "(resolved = false)", using: :btree

  create_table "clients", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                                       null: false
    t.integer  "user_id",                            limit: 8,                                  null: false
    t.boolean  "bought_something",                               default: false,                null: false
    t.integer  "ab_testing_group"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id",                        limit: 255
    t.string   "email",                              limit: 255
    t.boolean  "digests_enabled",                                default: true,                 null: false
    t.uuid     "code",                                           default: "uuid_generate_v4()"
    t.boolean  "subscription_popup_showed",                      default: false,                null: false
    t.boolean  "triggers_enabled",                               default: true,                 null: false
    t.datetime "last_trigger_mail_sent_at"
    t.boolean  "accepted_subscription",                          default: false,                null: false
    t.string   "location"
    t.date     "last_activity_at"
    t.boolean  "supply_trigger_sent"
    t.boolean  "web_push_enabled"
    t.datetime "last_web_push_sent_at"
    t.boolean  "web_push_subscription_popup_showed"
    t.boolean  "accepted_web_push_subscription"
    t.integer  "fb_id",                              limit: 8
    t.integer  "vk_id",                              limit: 8
    t.boolean  "email_confirmed"
    t.integer  "segment_ids",                                                                                array: true
    t.boolean  "digest_opened"
  end

  add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
  add_index "clients", ["email"], name: "index_clients_on_email", using: :btree
  add_index "clients", ["shop_id", "email", "digests_enabled", "id"], name: "index_clients_on_shop_id_and_digests_enabled", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "email", "triggers_enabled", "id"], name: "index_clients_on_shop_id_and_triggers_enabled", where: "((email IS NOT NULL) AND (triggers_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "external_id"], name: "index_clients_on_shop_id_and_external_id", where: "(external_id IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "last_activity_at"], name: "index_clients_on_shop_id_and_last_activity_at", where: "((email IS NOT NULL) AND (triggers_enabled IS TRUE) AND (last_activity_at IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "last_trigger_mail_sent_at"], name: "idx_clients_shop_id_last_trigger_email_nulls_first", where: "((triggers_enabled = true) AND (email IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "segment_ids"], name: "index_clients_on_shop_id_and_segment_ids", where: "(segment_ids IS NOT NULL)", using: :gin
  add_index "clients", ["shop_id", "subscription_popup_showed", "accepted_subscription"], name: "index_clients_on_shop_id_and_accepted_subscription", where: "((subscription_popup_showed = true) AND (accepted_subscription = true))", using: :btree
  add_index "clients", ["shop_id", "subscription_popup_showed"], name: "index_clients_on_shop_id_and_subscription_popup_showed", where: "(subscription_popup_showed = true)", using: :btree
  add_index "clients", ["shop_id", "user_id"], name: "index_clients_on_shop_id_and_user_id", using: :btree
  add_index "clients", ["shop_id", "web_push_enabled"], name: "index_clients_on_shop_id_and_web_push_enabled", where: "(web_push_enabled = true)", using: :btree
  add_index "clients", ["shop_id", "web_push_subscription_popup_showed"], name: "index_clients_on_shop_id_and_web_push_subscription_popup_showed", where: "(web_push_subscription_popup_showed = true)", using: :btree
  add_index "clients", ["shop_id"], name: "index_clients_on_shop_id", using: :btree
  add_index "clients", ["user_id"], name: "index_clients_on_user_id", using: :btree

  create_table "digest_mailing_batches", id: :bigserial, force: :cascade do |t|
    t.integer "digest_mailing_id", limit: 8,                   null: false
    t.integer "end_id",            limit: 8
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id",          limit: 8
    t.string  "test_email",        limit: 255
    t.integer "shop_id"
    t.integer "mailchimp_count"
    t.integer "mailchimp_offset"
    t.integer "segment_id"
  end

  add_index "digest_mailing_batches", ["digest_mailing_id"], name: "index_digest_mailing_batches_on_digest_mailing_id", using: :btree
  add_index "digest_mailing_batches", ["shop_id"], name: "index_digest_mailing_batches_on_shop_id", using: :btree

  create_table "digest_mailing_settings", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                             null: false
    t.boolean "on",                  default: false, null: false
    t.string  "sender",  limit: 255,                 null: false
  end

  add_index "digest_mailing_settings", ["shop_id"], name: "index_digest_mailing_settings_on_shop_id", using: :btree

  create_table "digest_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                    null: false
    t.string   "name",                        limit: 255,                    null: false
    t.string   "subject",                     limit: 255,                    null: false
    t.string   "items",                       limit: 255
    t.string   "state",                       limit: 255, default: "draft",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_mails_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "edit_mode",                   limit: 255, default: "simple", null: false
    t.text     "liquid_template"
    t.integer  "amount_of_recommended_items",             default: 9,        null: false
    t.string   "mailchimp_campaign_id"
    t.string   "mailchimp_list_id"
    t.integer  "images_dimension",                        default: 3
    t.string   "header",                                  default: "",       null: false
    t.text     "text",                                    default: "",       null: false
    t.integer  "theme_id",                    limit: 8
    t.string   "theme_type"
    t.jsonb    "template_data"
    t.string   "intro_text"
    t.integer  "segment_id"
    t.datetime "planing_at"
  end

  add_index "digest_mailings", ["shop_id", "theme_id", "theme_type"], name: "index_digest_mailings_theme", using: :btree
  add_index "digest_mailings", ["shop_id"], name: "index_digest_mailings_on_shop_id", using: :btree

  create_table "digest_mails", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                          null: false
    t.integer  "digest_mailing_id",       limit: 8,                                null: false
    t.integer  "digest_mailing_batch_id", limit: 8,                                null: false
    t.uuid     "code",                              default: "uuid_generate_v4()"
    t.boolean  "clicked",                           default: false,                null: false
    t.boolean  "opened",                            default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id",               limit: 8,                                null: false
    t.boolean  "bounced",                           default: false,                null: false
    t.date     "date"
  end

  add_index "digest_mails", ["client_id"], name: "index_digest_mails_on_client_id", using: :btree
  add_index "digest_mails", ["code"], name: "index_digest_mails_on_code", unique: true, using: :btree
  add_index "digest_mails", ["date", "shop_id"], name: "index_digest_mails_on_date_and_shop_id", using: :btree
  add_index "digest_mails", ["date"], name: "index_digest_mails_on_date", using: :btree
  add_index "digest_mails", ["digest_mailing_id"], name: "index_digest_mails_on_digest_mailing_id", using: :btree

  create_table "events", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                     null: false
    t.string   "name",            limit: 255,                 null: false
    t.text     "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processed",                   default: false, null: false
  end

  add_index "events", ["created_at"], name: "index_events_on_created_at", using: :btree
  add_index "events", ["name"], name: "index_events_on_name", using: :btree
  add_index "events", ["shop_id"], name: "index_events_on_shop_id", using: :btree

  create_table "interactions", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                    null: false
    t.integer  "user_id",          limit: 8, null: false
    t.integer  "item_id",          limit: 8, null: false
    t.integer  "code",                       null: false
    t.integer  "recommender_code"
    t.datetime "created_at",                 null: false
  end

  add_index "interactions", ["shop_id", "created_at", "recommender_code"], name: "interactions_shop_id_created_at_recommender_code_idx", where: "(code = 1)", using: :btree
  add_index "interactions", ["user_id"], name: "index_interactions_on_user_id", using: :btree

  create_table "item_categories", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.integer  "parent_id",          limit: 8
    t.string   "external_id",                  null: false
    t.string   "parent_external_id"
    t.string   "name"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "taxonomy"
  end

  add_index "item_categories", ["shop_id", "external_id"], name: "index_item_categories_on_shop_id_and_external_id", unique: true, using: :btree
  add_index "item_categories", ["shop_id"], name: "index_item_categories_with_taxonomy", where: "(taxonomy IS NOT NULL)", using: :btree
  add_index "item_categories", ["shop_id"], name: "index_item_categories_without_taxonomy", where: "((taxonomy IS NULL) AND (name IS NOT NULL))", using: :btree

  create_table "items", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                                              null: false
    t.string  "uniqid",                  limit: 255,                  null: false
    t.decimal "price"
    t.boolean "is_available",                         default: true,  null: false
    t.string  "name",                    limit: 255
    t.text    "description"
    t.text    "url"
    t.text    "image_url"
    t.boolean "widgetable",                           default: false, null: false
    t.string  "brand",                   limit: 255
    t.boolean "ignored",                              default: false, null: false
    t.jsonb   "locations",                            default: {},    null: false
    t.float   "sr"
    t.integer "sales_rate",              limit: 2
    t.string  "type_prefix"
    t.string  "vendor_code"
    t.string  "model"
    t.string  "fashion_gender",          limit: 1
    t.string  "fashion_wear_type",       limit: 20
    t.string  "fashion_feature",         limit: 20
    t.float   "child_age_min"
    t.float   "child_age_max"
    t.boolean "fmcg_hypoallergenic"
    t.string  "part_type",                                                         array: true
    t.string  "skin_type",                                                         array: true
    t.string  "condition",                                                         array: true
    t.jsonb   "fmcg_volume"
    t.boolean "fmcg_periodic"
    t.string  "barcode",                 limit: 1914
    t.string  "category_ids",                                                      array: true
    t.string  "location_ids",                                                      array: true
    t.integer "price_margin"
    t.string  "fashion_sizes",                                                     array: true
    t.string  "cosmetic_gender",         limit: 1
    t.boolean "cosmetic_hypoallergenic"
    t.string  "cosmetic_skin_part",                                                array: true
    t.string  "cosmetic_skin_type",                                                array: true
    t.string  "cosmetic_skin_condition",                                           array: true
    t.string  "cosmetic_hair_type",                                                array: true
    t.string  "cosmetic_hair_condition",                                           array: true
    t.jsonb   "cosmetic_volume"
    t.boolean "cosmetic_periodic"
    t.boolean "is_cosmetic"
    t.boolean "is_child"
    t.boolean "is_fashion"
    t.string  "child_gender",            limit: 1
    t.string  "child_type"
    t.boolean "is_fmcg"
    t.decimal "oldprice"
    t.string  "brand_downcase"
    t.boolean "discount"
    t.boolean "is_auto"
    t.jsonb   "auto_compatibility"
    t.boolean "auto_periodic"
    t.text    "auto_vds",                                                          array: true
    t.boolean "is_pets"
    t.string  "pets_breed"
    t.string  "pets_type"
    t.string  "pets_age"
    t.boolean "pets_periodic"
    t.string  "pets_size"
    t.string  "image_downloading_error"
    t.boolean "is_jewelry"
    t.string  "jewelry_gender"
    t.string  "jewelry_color"
    t.string  "jewelry_metal"
    t.string  "jewelry_gem"
    t.jsonb   "ring_sizes"
    t.jsonb   "bracelet_sizes"
    t.jsonb   "chain_sizes"
  end

  add_index "items", ["bracelet_sizes"], name: "index_items_on_bracelet_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (bracelet_sizes IS NOT NULL))", using: :gin
  add_index "items", ["brand"], name: "index_items_on_brand", where: "(brand IS NOT NULL)", using: :btree
  add_index "items", ["brand_downcase"], name: "index_items_on_brand_for_brand_campaign", where: "((brand_downcase IS NOT NULL) AND (category_ids IS NOT NULL))", using: :btree
  add_index "items", ["category_ids"], name: "index_items_on_category_ids", using: :gin
  add_index "items", ["category_ids"], name: "index_items_on_category_ids_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["chain_sizes"], name: "index_items_on_chain_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (chain_sizes IS NOT NULL))", using: :gin
  add_index "items", ["fashion_sizes", "fashion_wear_type"], name: "index_items_on_sizes_recommendable", where: "((is_available IS TRUE) AND (ignored IS FALSE) AND ((fashion_sizes IS NOT NULL) AND (fashion_wear_type IS NOT NULL)))", using: :gin
  add_index "items", ["jewelry_color"], name: "index_items_on_jewelry_color", where: "((is_jewelry IS TRUE) AND (jewelry_color IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_gem"], name: "index_items_on_jewelry_gem", where: "((is_jewelry IS TRUE) AND (jewelry_gem IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_gender"], name: "index_items_on_jewelry_gender", where: "((is_jewelry IS TRUE) AND (jewelry_gender IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_metal"], name: "index_items_on_jewelry_metal", where: "((is_jewelry IS TRUE) AND (jewelry_metal IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["locations"], name: "index_items_on_locations", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["pets_age"], name: "index_items_on_pets_age", where: "((is_pets IS TRUE) AND (pets_age IS NOT NULL))", using: :btree
  add_index "items", ["pets_breed"], name: "index_items_on_pets_breed", where: "((is_pets IS TRUE) AND (pets_breed IS NOT NULL))", using: :btree
  add_index "items", ["pets_size"], name: "index_items_on_pets_size", where: "((is_pets IS TRUE) AND (pets_size IS NOT NULL))", using: :btree
  add_index "items", ["pets_type"], name: "index_items_on_pets_type", where: "((is_pets IS TRUE) AND (pets_type IS NOT NULL))", using: :btree
  add_index "items", ["price", "shop_id"], name: "index_items_on_price", where: "((is_available = true) AND (ignored = false) AND (price IS NOT NULL))", using: :btree
  add_index "items", ["ring_sizes"], name: "index_items_on_ring_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (ring_sizes IS NOT NULL))", using: :gin
  add_index "items", ["shop_id", "brand", "id"], name: "index_items_on_shop_and_brand", where: "((is_available = true) AND (ignored = false) AND (widgetable = true) AND (brand IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "discount"], name: "index_items_on_shop_id_and_discount", where: "(discount IS NOT NULL)", using: :btree
  add_index "items", ["shop_id", "fashion_gender"], name: "index_items_on_shop_id_and_fashion_gender", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "ignored"], name: "index_items_on_shop_id_and_ignored", where: "(ignored = true)", using: :btree
  add_index "items", ["shop_id", "image_downloading_error"], name: "index_items_on_shop_id_and_image_downloading_error", where: "(image_downloading_error IS NOT NULL)", using: :btree
  add_index "items", ["shop_id", "is_available", "ignored", "id"], name: "shop_available_index", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "price_margin", "sales_rate"], name: "index_items_on_shop_id_and_price_margin_and_sales_rate", where: "((price_margin IS NOT NULL) AND (is_available IS TRUE) AND (ignored IS FALSE))", using: :btree
  add_index "items", ["shop_id", "sales_rate"], name: "available_items_with_sales_rate", where: "((is_available = true) AND (ignored = false) AND (sales_rate IS NOT NULL) AND (sales_rate > 0))", using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid_and_is_available", where: "(is_available = true)", using: :btree
  add_index "items", ["shop_id", "widgetable", "is_available", "ignored"], name: "widgetable_shop", where: "((widgetable = true) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id"], name: "index_items_on_shop_id", using: :btree

  create_table "mailings_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                     null: false
    t.string   "send_from",           limit: 255,             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mailing_service",                 default: 0
    t.string   "getresponse_api_key"
    t.string   "mailchimp_api_key"
    t.string   "unsubscribe_message"
  end

  create_table "order_items", id: :bigserial, force: :cascade do |t|
    t.integer "order_id",       limit: 8,               null: false
    t.integer "item_id",        limit: 8,               null: false
    t.integer "action_id",      limit: 8,               null: false
    t.integer "amount",                     default: 1, null: false
    t.string  "recommended_by", limit: 255
    t.integer "shop_id"
  end

  add_index "order_items", ["item_id"], name: "index_order_items_on_item_id", using: :btree
  add_index "order_items", ["order_id"], name: "index_order_items_on_order_id", using: :btree
  add_index "order_items", ["shop_id"], name: "index_order_items_on_shop_id", using: :btree

  create_table "orders", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                       null: false
    t.integer  "user_id",           limit: 8,                   null: false
    t.string   "uniqid",            limit: 255,                 null: false
    t.datetime "date",                                          null: false
    t.decimal  "value",                         default: 0.0,   null: false
    t.boolean  "recommended",                   default: false, null: false
    t.integer  "ab_testing_group"
    t.decimal  "recommended_value",             default: 0.0,   null: false
    t.decimal  "common_value",                  default: 0.0,   null: false
    t.integer  "source_id",         limit: 8
    t.string   "source_type"
    t.integer  "status",                        default: 0,     null: false
    t.date     "status_date"
    t.boolean  "compensated"
    t.string   "reputation_key"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "date"], name: "index_orders_on_shop_id_and_date", using: :btree
  add_index "orders", ["shop_id", "source_type", "date"], name: "index_orders_on_shop_id_and_source_type_and_date", where: "(source_type IS NOT NULL)", using: :btree
  add_index "orders", ["shop_id", "status", "status_date"], name: "index_orders_on_shop_id_and_status_and_status_date", using: :btree
  add_index "orders", ["shop_id", "uniqid"], name: "index_orders_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "orders", ["shop_id"], name: "index_orders_on_shop_id", using: :btree
  add_index "orders", ["source_type", "source_id"], name: "index_orders_on_source_type_and_source_id", using: :btree
  add_index "orders", ["uniqid"], name: "index_orders_on_uniqid", using: :btree
  add_index "orders", ["user_id"], name: "index_orders_on_user_id", using: :btree

  create_table "recommendations_requests", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                           null: false
    t.integer  "category_id",                                       null: false
    t.string   "recommender_type",      limit: 255,                 null: false
    t.boolean  "clicked",                           default: false, null: false
    t.integer  "recommendations_count",                             null: false
    t.text     "recommended_ids",                   default: [],    null: false, array: true
    t.decimal  "duration",                                          null: false
    t.integer  "user_id",               limit: 8
    t.string   "session_code",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recommendations_requests", ["shop_id"], name: "index_recommendations_requests_on_shop_id", using: :btree

  create_table "reputations", id: :bigserial, force: :cascade do |t|
    t.string   "name"
    t.integer  "rating"
    t.text     "plus"
    t.text     "minus"
    t.text     "comment"
    t.datetime "published_at"
    t.integer  "shop_id"
    t.integer  "entity_id",    limit: 8
    t.string   "entity_type"
    t.integer  "parent_id",    limit: 8
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "status",                 default: 0, null: false
    t.integer  "client_id",    limit: 8
  end

  add_index "reputations", ["entity_type", "entity_id"], name: "index_reputations_on_entity_type_and_entity_id", using: :btree
  add_index "reputations", ["parent_id"], name: "index_reputations_on_parent_id", using: :btree
  add_index "reputations", ["shop_id"], name: "index_reputations_on_shop_id", using: :btree

  create_table "search_queries", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",           null: false
    t.integer "user_id", limit: 8, null: false
    t.date    "date",              null: false
    t.string  "query",             null: false
  end

  add_index "search_queries", ["shop_id", "date", "user_id"], name: "index_search_queries_on_shop_id_and_date_and_user_id", using: :btree
  add_index "search_queries", ["shop_id", "query"], name: "index_search_queries_on_shop_id_and_query", using: :btree

  create_table "shop_locations", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.string   "external_id",                  null: false
    t.string   "name",                         null: false
    t.string   "external_type"
    t.integer  "parent_id",          limit: 8
    t.string   "parent_external_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "shop_locations", ["shop_id", "external_id"], name: "index_shop_locations_on_shop_id_and_external_id", unique: true, using: :btree

  create_table "shop_metrics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "orders",                             default: 0,   null: false
    t.integer "real_orders",                        default: 0,   null: false
    t.decimal "revenue",                            default: 0.0, null: false
    t.decimal "real_revenue",                       default: 0.0, null: false
    t.integer "visitors",                           default: 0,   null: false
    t.integer "products_viewed",                    default: 0,   null: false
    t.integer "triggers_enabled_count",             default: 0,   null: false
    t.integer "triggers_orders",                    default: 0,   null: false
    t.decimal "triggers_revenue",                   default: 0.0, null: false
    t.integer "digests_orders",                     default: 0,   null: false
    t.decimal "digests_revenue",                    default: 0.0, null: false
    t.integer "abandoned_products",                 default: 0,   null: false
    t.decimal "abandoned_money",                    default: 0.0, null: false
    t.date    "date",                                             null: false
    t.integer "triggers_sent",                      default: 0,   null: false
    t.integer "triggers_clicked",                   default: 0,   null: false
    t.decimal "triggers_revenue_real",              default: 0.0, null: false
    t.integer "triggers_orders_real",               default: 0,   null: false
    t.integer "digests_sent",                       default: 0,   null: false
    t.integer "digests_clicked",                    default: 0,   null: false
    t.decimal "digests_revenue_real",               default: 0.0, null: false
    t.integer "digests_orders_real",                default: 0,   null: false
    t.integer "subscription_popup_showed",          default: 0
    t.integer "subscription_accepted",              default: 0
    t.integer "orders_original_count",              default: 0
    t.decimal "orders_original_revenue",            default: 0.0
    t.integer "orders_recommended_count",           default: 0
    t.decimal "orders_recommended_revenue",         default: 0.0
    t.integer "product_views_total",                default: 0
    t.integer "product_views_recommended",          default: 0
    t.jsonb   "top_products",                                                  array: true
    t.jsonb   "products_statistics"
    t.integer "web_push_subscription_popup_showed", default: 0
    t.integer "web_push_subscription_accepted",     default: 0
    t.integer "web_push_triggers_sent",             default: 0,   null: false
    t.integer "web_push_triggers_clicked",          default: 0,   null: false
    t.integer "web_push_triggers_orders",           default: 0,   null: false
    t.integer "web_push_triggers_revenue",          default: 0,   null: false
    t.integer "web_push_triggers_orders_real",      default: 0,   null: false
    t.integer "web_push_triggers_revenue_real",     default: 0,   null: false
    t.integer "orders_with_recommender_count",      default: 0,   null: false
    t.integer "web_push_digests_sent",              default: 0,   null: false
    t.integer "web_push_digests_clicked",           default: 0,   null: false
    t.integer "web_push_digests_orders",            default: 0,   null: false
    t.integer "web_push_digests_revenue",           default: 0,   null: false
    t.integer "web_push_digests_orders_real",       default: 0,   null: false
    t.integer "web_push_digests_revenue_real",      default: 0,   null: false
    t.integer "remarketing_carts",                  default: 0,   null: false
    t.integer "remarketing_impressions",            default: 0,   null: false
    t.integer "remarketing_clicks",                 default: 0,   null: false
    t.integer "remarketing_orders",                 default: 0,   null: false
    t.integer "remarketing_revenue",                default: 0,   null: false
    t.integer "recommendation_requests"
  end

  add_index "shop_metrics", ["shop_id", "date"], name: "index_shop_metrics_on_shop_id_and_date", unique: true, using: :btree
  add_index "shop_metrics", ["shop_id"], name: "index_shop_metrics_on_shop_id", using: :btree

  create_table "shop_themes", id: :bigserial, force: :cascade do |t|
    t.string   "name",                         null: false
    t.integer  "theme_id",                     null: false
    t.integer  "shop_id"
    t.string   "theme_type",                   null: false
    t.jsonb    "variables"
    t.text     "compiled_css"
    t.boolean  "is_custom",    default: false, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "source_type"
  end

  add_index "shop_themes", ["shop_id", "theme_type"], name: "index_shop_themes_on_shop_id_and_theme_type", using: :btree
  add_index "shop_themes", ["shop_id"], name: "index_shop_themes_on_shop_id", using: :btree

  create_table "subscribe_for_categories", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",          limit: 8
    t.integer  "item_category_id", limit: 8
    t.datetime "subscribed_at"
  end

  add_index "subscribe_for_categories", ["shop_id", "subscribed_at"], name: "index_category_subscription_for_cleanup", using: :btree
  add_index "subscribe_for_categories", ["shop_id", "user_id", "item_category_id"], name: "index_category_subscription_uniq", unique: true, using: :btree
  add_index "subscribe_for_categories", ["shop_id", "user_id"], name: "index_category_subscription_for_triggers", using: :btree

  create_table "subscribe_for_product_availables", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",       limit: 8
    t.integer  "item_id",       limit: 8
    t.datetime "subscribed_at"
  end

  add_index "subscribe_for_product_availables", ["shop_id", "user_id", "item_id"], name: "index_subscribe_for_product_available_uniq", unique: true, using: :btree
  add_index "subscribe_for_product_availables", ["shop_id", "user_id"], name: "index_subscribe_for_product_available_for_user", using: :btree

  create_table "subscribe_for_product_prices", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",       limit: 8
    t.integer  "item_id",       limit: 8
    t.datetime "subscribed_at"
    t.decimal  "price",                   null: false
  end

  add_index "subscribe_for_product_prices", ["shop_id", "user_id", "item_id"], name: "index_subscribe_for_product_price_uniq", unique: true, using: :btree
  add_index "subscribe_for_product_prices", ["shop_id", "user_id"], name: "index_subscribe_for_product_price_for_user", using: :btree

  create_table "subscriptions_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                          null: false
    t.boolean  "enabled",                          default: false, null: false
    t.boolean  "overlay",                          default: true,  null: false
    t.text     "header",                                           null: false
    t.text     "text",                                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture_file_name",    limit: 255
    t.string   "picture_content_type", limit: 255
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "button"
    t.text     "agreement"
    t.integer  "popup_type",                       default: 0,     null: false
    t.integer  "timer",                            default: 90,    null: false
    t.boolean  "timer_enabled",                    default: true,  null: false
    t.integer  "pager",                            default: 5,     null: false
    t.boolean  "pager_enabled",                    default: false, null: false
    t.integer  "cursor",                           default: 50,    null: false
    t.boolean  "cursor_enabled",                   default: false, null: false
    t.boolean  "products",                         default: true,  null: false
    t.text     "successfully"
    t.integer  "theme_id",             limit: 8
    t.string   "theme_type"
  end

  add_index "subscriptions_settings", ["shop_id", "theme_id", "theme_type"], name: "index_subscriptions_settings_theme", using: :btree

  create_table "trigger_mailing_queues", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",           limit: 8
    t.string   "email"
    t.string   "trigger_type"
    t.datetime "triggered_at"
    t.string   "recommended_items",           array: true
    t.string   "source_items",                array: true
    t.string   "trigger_mail_code"
  end

  add_index "trigger_mailing_queues", ["shop_id"], name: "index_trigger_mailing_queues_on_shop_id", using: :btree
  add_index "trigger_mailing_queues", ["triggered_at"], name: "index_trigger_mailing_queues_on_triggered_at", using: :btree

  create_table "trigger_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                 null: false
    t.string   "trigger_type",                limit: 255,                 null: false
    t.string   "subject",                     limit: 255,                 null: false
    t.boolean  "enabled",                                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "liquid_template"
    t.string   "mailchimp_campaign_id"
    t.datetime "activated_at"
    t.integer  "amount_of_recommended_items",             default: 9,     null: false
    t.integer  "images_dimension",                        default: 3,     null: false
    t.integer  "theme_id",                    limit: 8
    t.string   "theme_type"
    t.jsonb    "template_data"
    t.boolean  "simple_editor",                           default: true,  null: false
    t.string   "intro_text"
  end

  add_index "trigger_mailings", ["shop_id", "theme_id", "theme_type"], name: "index_trigger_mailings_theme", using: :btree
  add_index "trigger_mailings", ["shop_id", "trigger_type"], name: "index_trigger_mailings_on_shop_id_and_trigger_type", unique: true, using: :btree

  create_table "trigger_mails", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                     null: false
    t.text     "trigger_data",                                                null: false
    t.uuid     "code",                         default: "uuid_generate_v4()"
    t.boolean  "clicked",                      default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "opened",                       default: false,                null: false
    t.integer  "trigger_mailing_id", limit: 8,                                null: false
    t.boolean  "bounced",                      default: false,                null: false
    t.integer  "client_id",          limit: 8,                                null: false
    t.date     "date"
  end

  add_index "trigger_mails", ["code"], name: "index_trigger_mails_on_code", unique: true, using: :btree
  add_index "trigger_mails", ["date", "shop_id"], name: "index_trigger_mails_on_date_and_shop_id", using: :btree
  add_index "trigger_mails", ["date"], name: "index_trigger_mails_on_date", using: :btree
  add_index "trigger_mails", ["shop_id", "trigger_mailing_id", "opened"], name: "index_trigger_mails_on_shop_id_and_trigger_mailing_id", using: :btree
  add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

  create_table "visits", id: :bigserial, force: :cascade do |t|
    t.date    "date",                          null: false
    t.integer "user_id", limit: 8,             null: false
    t.integer "shop_id",                       null: false
    t.integer "pages",             default: 1, null: false
  end

  add_index "visits", ["date", "user_id", "shop_id"], name: "index_visits_on_date_and_user_id_and_shop_id", unique: true, using: :btree
  add_index "visits", ["shop_id", "date"], name: "index_visits_on_shop_id_and_date", using: :btree
  add_index "visits", ["user_id"], name: "index_visits_on_user_id", using: :btree

  create_table "web_push_digest_batches", id: :bigserial, force: :cascade do |t|
    t.integer "web_push_digest_id", limit: 8,                 null: false
    t.integer "end_id",             limit: 8
    t.boolean "completed",                    default: false, null: false
    t.integer "start_id",           limit: 8
    t.integer "shop_id"
  end

  add_index "web_push_digest_batches", ["shop_id"], name: "index_web_push_digest_batches_on_shop_id", using: :btree
  add_index "web_push_digest_batches", ["web_push_digest_id"], name: "index_web_push_digest_batches_on_web_push_digest_id", using: :btree

  create_table "web_push_digest_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                           null: false
    t.uuid     "code",                               default: "uuid_generate_v4()"
    t.boolean  "clicked",                            default: false,                null: false
    t.integer  "web_push_digest_id",       limit: 8,                                null: false
    t.boolean  "unsubscribed",                       default: false,                null: false
    t.integer  "client_id",                limit: 8,                                null: false
    t.date     "date"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "web_push_digest_batch_id", limit: 8,                                null: false
    t.boolean  "showed",                             default: false,                null: false
  end

  add_index "web_push_digest_messages", ["code"], name: "index_web_push_digest_messages_on_code", unique: true, using: :btree
  add_index "web_push_digest_messages", ["date", "shop_id"], name: "index_web_push_digest_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_digest_messages", ["date"], name: "index_web_push_digest_messages_on_date", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed", where: "(showed IS TRUE)", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_unsubscribed", where: "(unsubscribed = false)", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked IS TRUE)", using: :btree
  add_index "web_push_digest_messages", ["web_push_digest_id"], name: "index_web_push_digest_messages_on_web_push_digest_id", using: :btree

  create_table "web_push_digests", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                             null: false
    t.string   "subject",              limit: 255,                    null: false
    t.string   "state",                limit: 255,  default: "draft", null: false
    t.integer  "total_mails_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "message",              limit: 125
    t.string   "url",                  limit: 4096
    t.jsonb    "actions"
    t.string   "additional_image"
  end

  add_index "web_push_digests", ["shop_id"], name: "index_web_push_digests_on_shop_id", using: :btree

  create_table "web_push_subscriptions_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                              null: false
    t.boolean  "enabled",                              default: false, null: false
    t.boolean  "overlay",                              default: true,  null: false
    t.text     "header",                                               null: false
    t.text     "text",                                                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture_file_name",        limit: 255
    t.string   "picture_content_type",     limit: 255
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "button"
    t.text     "agreement"
    t.boolean  "manual_mode",                          default: false
    t.string   "safari_website_push_id"
    t.string   "certificate_password"
    t.string   "certificate_file_name"
    t.string   "certificate_content_type"
    t.integer  "certificate_file_size"
    t.datetime "certificate_updated_at"
    t.text     "pem_content"
    t.string   "service_worker_path"
    t.text     "successfully"
    t.integer  "popup_type",                           default: 0,     null: false
    t.integer  "timer",                                default: 30,    null: false
    t.boolean  "timer_enabled",                        default: true,  null: false
    t.integer  "pager",                                default: 5,     null: false
    t.boolean  "pager_enabled",                        default: false, null: false
    t.integer  "cursor",                               default: 50,    null: false
    t.boolean  "cursor_enabled",                       default: false, null: false
    t.boolean  "products",                             default: false, null: false
    t.integer  "theme_id",                 limit: 8
    t.string   "theme_type"
    t.string   "subdomain"
  end

  add_index "web_push_subscriptions_settings", ["shop_id", "theme_id", "theme_type"], name: "index_web_push_subscriptions_settings_theme", using: :btree
  add_index "web_push_subscriptions_settings", ["subdomain"], name: "index_web_push_subscriptions_settings_on_subdomain", unique: true, using: :btree

  create_table "web_push_token_errors", id: :bigserial, force: :cascade do |t|
    t.integer  "client_id",  limit: 8
    t.integer  "shop_id"
    t.jsonb    "message"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "web_push_tokens", id: :bigserial, force: :cascade do |t|
    t.integer  "client_id",  limit: 8, null: false
    t.integer  "shop_id",    limit: 8, null: false
    t.jsonb    "token"
    t.string   "browser"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "web_push_tokens", ["client_id", "token"], name: "index_web_push_tokens_on_client_id_and_token", unique: true, using: :btree
  add_index "web_push_tokens", ["client_id"], name: "index_web_push_tokens_on_client_id", using: :btree
  add_index "web_push_tokens", ["shop_id"], name: "index_web_push_tokens_on_shop_id", using: :btree

  create_table "web_push_trigger_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                      null: false
    t.text     "trigger_data",                                                 null: false
    t.uuid     "code",                          default: "uuid_generate_v4()"
    t.boolean  "clicked",                       default: false,                null: false
    t.integer  "web_push_trigger_id", limit: 8,                                null: false
    t.boolean  "unsubscribed",                  default: false,                null: false
    t.integer  "client_id",           limit: 8,                                null: false
    t.date     "date"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.boolean  "showed",                        default: false,                null: false
  end

  add_index "web_push_trigger_messages", ["code"], name: "index_web_push_trigger_messages_on_code", unique: true, using: :btree
  add_index "web_push_trigger_messages", ["date", "shop_id"], name: "index_web_push_trigger_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_trigger_messages", ["date"], name: "index_web_push_trigger_messages_on_date", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_trigger_id_and_showed", where: "(showed IS TRUE)", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked IS TRUE)", using: :btree
  add_index "web_push_trigger_messages", ["web_push_trigger_id"], name: "index_web_push_trigger_messages_on_web_push_trigger_id", using: :btree

  create_table "web_push_triggers", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                  null: false
    t.string   "trigger_type", limit: 255,                 null: false
    t.string   "subject",      limit: 255,                 null: false
    t.boolean  "enabled",                  default: false, null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "message",      limit: 125
  end

end
