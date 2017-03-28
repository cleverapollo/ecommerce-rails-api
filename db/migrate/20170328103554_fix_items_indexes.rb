class FixItemsIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    # Items
    remove_index :items, name: 'shop_available_index'
    add_index :items, [:shop_id, :is_available, :ignored], where: 'is_available = true AND ignored = false', name: 'shop_available_index', algorithm: :concurrently
    remove_index :items, name: 'widgetable_shop'
    add_index :items, [:shop_id, :widgetable, :is_available, :ignored], where: 'widgetable = true AND is_available = true AND ignored = false', name: 'widgetable_shop', algorithm: :concurrently
    add_index :items, [:shop_id, :ignored], where: 'ignored = true', name: 'index_items_on_shop_id_and_ignored', algorithm: :concurrently

    # Clients
    remove_index :clients, name: 'index_clients_on_shop_id_and_accepted_subscription'
    add_index :clients, [:shop_id, :subscription_popup_showed, :accepted_subscription], where: 'subscription_popup_showed = true AND accepted_subscription = true', name: 'index_clients_on_shop_id_and_accepted_subscription', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_subscription_popup_showed'
    add_index :clients, [:shop_id, :subscription_popup_showed], where: 'subscription_popup_showed = true', name: 'index_clients_on_shop_id_and_subscription_popup_showed', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_web_push_subscription_popup_showed'
    add_index :clients, [:shop_id, :web_push_subscription_popup_showed], where: 'web_push_subscription_popup_showed = true', name: 'index_clients_on_shop_id_and_web_push_subscription_popup_showed', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_web_push_enabled'
    add_index :clients, [:shop_id, :web_push_enabled], where: 'web_push_enabled = true', name: 'index_clients_on_shop_id_and_web_push_enabled', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_accepted_web_push_subscription'
    remove_index :clients, name: 'index_clients_last_web_push_sent_at'
  end

  def down
    # Items
    remove_index :items, name: 'shop_available_index'
    add_index :items, [:shop_id], name: 'shop_available_index', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
    remove_index :items, name: 'widgetable_shop'
    add_index :items, [:shop_id], name: 'widgetable_shop', where: '((widgetable = true) AND (is_available = true) AND (ignored = false))', algorithm: :concurrently
    remove_index :items, name: 'index_items_on_shop_id_and_ignored'

    # Clients
    remove_index :clients, name: 'index_clients_on_shop_id_and_accepted_subscription'
    add_index :clients, [:shop_id, :accepted_subscription], name: 'index_clients_on_shop_id_and_accepted_subscription', where: '((accepted_subscription IS TRUE) AND (subscription_popup_showed IS TRUE))'
    remove_index :clients, name: 'index_clients_on_shop_id_and_subscription_popup_showed'
    add_index :clients, [:shop_id, :subscription_popup_showed], name: 'index_clients_on_shop_id_and_subscription_popup_showed', where: '(subscription_popup_showed IS TRUE)', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_web_push_subscription_popup_showed'
    add_index :clients, [:shop_id, :web_push_subscription_popup_showed], name: 'index_clients_on_shop_id_and_web_push_subscription_popup_showed', where: '(web_push_subscription_popup_showed IS TRUE)', algorithm: :concurrently
    remove_index :clients, name: 'index_clients_on_shop_id_and_web_push_enabled'
    add_index :clients, [:shop_id, :web_push_enabled], name: 'index_clients_on_shop_id_and_web_push_enabled', where: '(web_push_enabled IS TRUE)', algorithm: :concurrently
    add_index :clients, [:shop_id, :accepted_web_push_subscription], name: 'index_clients_on_shop_id_and_accepted_web_push_subscription', where: '((accepted_web_push_subscription IS TRUE) AND (web_push_subscription_popup_showed IS TRUE))', algorithm: :concurrently
    add_index :clients, [:shop_id, :web_push_enabled, :last_web_push_sent_at], name: 'index_clients_last_web_push_sent_at', where: '((web_push_enabled IS TRUE) AND (last_web_push_sent_at IS NOT NULL))', algorithm: :concurrently
  end
end
