class AddSubscriberToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :subscription_popup_showed, :integer, default: 0
    add_column :shop_metrics, :subscription_accepted, :integer, default: 0
    remove_index :clients, name: :index_clients_on_accepted_subscription_and_shop_id
    remove_index :clients, name: :index_clients_on_subscription_popup_showed_and_shop_id
    add_index :clients, [:shop_id, :accepted_subscription], where: '(accepted_subscription IS TRUE AND subscription_popup_showed IS TRUE)', using: :btree
    add_index :clients, [:shop_id, :subscription_popup_showed], where: '(subscription_popup_showed IS TRUE)', using: :btree
  end
end
