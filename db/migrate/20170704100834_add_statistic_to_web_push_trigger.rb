class AddStatisticToWebPushTrigger < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_msg_on_shop_id_and_trigger_id_and_showed'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_msg_on_shop_id_and_web_push_trigger_id'
    add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_trigger_id_and_showed", where: "showed = true", algorithm: :concurrently
    add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_web_push_trigger_id", where: "clicked = true", algorithm: :concurrently
    add_index :web_push_trigger_messages, [:shop_id, :web_push_trigger_id], name: 'index_web_push_trigger_msg_on_shop_and_trigger_unsubscribed', where: 'unsubscribed = true', algorithm: :concurrently
    add_column :web_push_triggers, :statistic, :jsonb
  end

  def down
    remove_column :web_push_triggers, :statistic
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_web_push_trigger_msg_on_shop_and_trigger_unsubscribed'
  end
end
