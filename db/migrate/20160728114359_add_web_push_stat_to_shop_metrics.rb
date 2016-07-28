class AddWebPushStatToShopMetrics < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :web_push_subscription_popup_showed, :integer, default: 0
    add_column :shop_metrics, :web_push_subscription_accepted, :integer, default: 0
  end
end
