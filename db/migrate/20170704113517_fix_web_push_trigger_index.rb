class FixWebPushTriggerIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_messages_on_date'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_messages_on_web_push_trigger_id'
    add_index "web_push_trigger_messages", ["web_push_trigger_id", :date], name: 'index_web_push_trigger_messages_on_web_push_trigger_id', algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_messages_on_date'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_messages_on_web_push_digest_id'
    add_index "web_push_digest_messages", ["web_push_digest_id", :date], name: "index_web_push_digest_messages_on_web_push_digest_id", algorithm: :concurrently

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_trigger_mails_on_date'

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_digest_mails_on_date'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_digest_mails_on_digest_mailing_id'
    add_index "digest_mails", ["digest_mailing_id", :date], name: "index_digest_mails_on_digest_mailing_id", algorithm: :concurrently
  end

  def down
    add_index "web_push_trigger_messages", ["date"], name: "index_web_push_trigger_messages_on_date", algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_messages_on_web_push_trigger_id'
    add_index "web_push_trigger_messages", ["web_push_trigger_id"], name: 'index_web_push_trigger_messages_on_web_push_trigger_id', algorithm: :concurrently

    add_index "web_push_digest_messages", ["date"], name: "index_web_push_digest_messages_on_date", algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_digest_messages_on_web_push_digest_id'
    add_index "web_push_digest_messages", ["web_push_digest_id"], name: "index_web_push_digest_messages_on_web_push_digest_id", algorithm: :concurrently

    add_index "trigger_mails", ["date"], name: "index_trigger_mails_on_date", algorithm: :concurrently

    add_index "digest_mails", ["date"], name: "index_digest_mails_on_date", algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_digest_mails_on_digest_mailing_id'
    add_index "digest_mails", ["digest_mailing_id"], name: "index_digest_mails_on_digest_mailing_id", algorithm: :concurrently
  end
end
