class AddRemarketingMetrics < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :remarketing_carts, :integer, default: 0, null: false
    add_column :shop_metrics, :remarketing_impressions, :integer, default: 0, null: false
    add_column :shop_metrics, :remarketing_clicks, :integer, default: 0, null: false
    add_column :shop_metrics, :remarketing_orders, :integer, default: 0, null: false
    add_column :shop_metrics, :remarketing_revenue, :integer, default: 0, null: false
  end
end
