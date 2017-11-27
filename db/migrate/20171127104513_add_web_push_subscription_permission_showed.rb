class AddWebPushSubscriptionPermissionShowed < ActiveRecord::Migration
  def change
    add_column :clients, :web_push_subscription_permission_showed, :boolean
    add_column :shop_metrics, :web_push_subscription_permission_showed, :integer, default: 0
  end
end
