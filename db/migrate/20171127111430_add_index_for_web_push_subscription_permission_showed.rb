class AddIndexForWebPushSubscriptionPermissionShowed < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :clients, [:shop_id, :web_push_subscription_permission_showed], where: "web_push_subscription_permission_showed = true", name: "index_clients_on_shop_id_and_web_push_subscription_perm_showed", algorithm: :concurrently
  end
end
