class AddCountFieldsToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :triggers_sent, :integer, null: false, default: 0
    add_column :shop_metrics, :triggers_clicked, :integer, null: false, default: 0
    add_column :shop_metrics, :triggers_revenue_real, :decimal, null: false, default: 0.0
    add_column :shop_metrics, :triggers_orders_real, :integer, null: false, default: 0
    add_column :shop_metrics, :digests_sent, :integer, null: false, default: 0
    add_column :shop_metrics, :digests_clicked, :integer, null: false, default: 0
    add_column :shop_metrics, :digests_revenue_real, :decimal, null: false, default: 0.0
    add_column :shop_metrics, :digests_orders_real, :integer, null: false, default: 0
    remove_column :shop_metrics, :orders_quality
    remove_column :shop_metrics, :conversion
    remove_column :shop_metrics, :arpu
    remove_column :shop_metrics, :arppu
    remove_column :shop_metrics, :triggers_ctr
    remove_column :shop_metrics, :digests_ctr
  end
end
