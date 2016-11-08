class AddWebPushTriggersToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :web_push_triggers_sent, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_triggers_clicked, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_triggers_orders, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_triggers_revenue, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_triggers_orders_real, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_triggers_revenue_real, :integer, default: 0, null: false
  end
end
