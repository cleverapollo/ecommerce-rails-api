class FixClientEmailIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    add_index 'clients', [:email, :shop_id, :id], name: 'index_clients_on_email_new', where: 'email IS NOT NULL', order: { id: :desc }, algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_email'
    execute 'ALTER INDEX index_clients_on_email_new RENAME TO index_clients_on_email'

    add_index :clients, [:shop_id, :id], name: 'index_client_on_shop_id_and_email_present_new', where: '(email IS NOT NULL)', order: { id: :desc }, algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_on_shop_id_and_email_present'
    execute 'ALTER INDEX index_client_on_shop_id_and_email_present_new RENAME TO index_client_on_shop_id_and_email_present'

    execute 'DROP INDEX CONCURRENTLY IF EXISTS widgetable_shop'
    add_index "items", ["shop_id", "id"], name: "widgetable_shop", where: "((widgetable = true) AND (is_available = true) AND (ignored = false))", algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_social_merge'
    add_index :clients, [:shop_id, :vk_id, :fb_id], name: 'index_clients_on_social_merge', where: 'vk_id IS NOT NULL OR fb_id IS NOT NULL', algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_actions_on_shop_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS buying_now_index'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_items_on_shop_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_orders_on_shop_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_profile_events_on_user_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_profile_events_on_user_id_and_industry_and_property'

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id'
    add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed", where: 'showed = TRUE', algorithm: :concurrently
    add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id", where: 'clicked = TRUE', algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_messages_on_client_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_messages_on_client_id'
    add_index :web_push_digest_messages, [:client_id], name: 'index_web_push_digest_messages_on_client_id', algorithm: :concurrently
    add_index :web_push_trigger_messages, [:client_id], name: 'index_web_push_trigger_messages_on_client_id', algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_subscribe_for_categories_on_user_id'
    add_index :subscribe_for_categories, [:user_id], name: 'index_subscribe_for_categories_on_user_id', algorithm: :concurrently

    execute 'DROP FOREIGN TABLE IF EXISTS sessions_master'
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_email'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_on_shop_id_and_email_present'
    add_index "clients", ["shop_id"], name: "index_client_on_shop_id_and_email_present", where: "(email IS NOT NULL)", algorithm: :concurrently
    add_index 'clients', [:email], name: 'index_clients_on_email', algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS widgetable_shop'
    add_index "items", ["shop_id", "widgetable", "is_available", "ignored"], name: "widgetable_shop", where: "((widgetable = true) AND (is_available = true) AND (ignored = false))", algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_social_merge'
    add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", algorithm: :concurrently
    add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", algorithm: :concurrently
    add_index "items", ["shop_id"], name: "index_items_on_shop_id", algorithm: :concurrently
    add_index "orders", ["shop_id"], name: "index_orders_on_shop_id", algorithm: :concurrently
    add_index "profile_events", ["user_id"], name: "index_profile_events_on_user_id", algorithm: :concurrently
    add_index "profile_events", ["user_id", "industry", "property"], name: "index_profile_events_on_user_id_and_industry_and_property", algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id'
    add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed", where: "(showed IS TRUE)", algorithm: :concurrently
    add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked IS TRUE)", algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_messages_on_client_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_messages_on_client_id'

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_subscribe_for_categories_on_user_id'

  end
end
