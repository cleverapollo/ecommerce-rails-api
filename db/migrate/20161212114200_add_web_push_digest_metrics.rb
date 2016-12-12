class AddWebPushDigestMetrics < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :web_push_digests_sent, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_digests_clicked, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_digests_orders, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_digests_revenue, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_digests_orders_real, :integer, default: 0, null: false
    add_column :shop_metrics, :web_push_digests_revenue_real, :integer, default: 0, null: false
  end
end
