class AddWebPushSubscriptionPopupShowed < ActiveRecord::Migration
  def change
    add_column :clients, :web_push_subscription_popup_showed, :boolean
    add_column :clients, :accepted_web_push_subscription, :boolean
    add_index :clients, [:shop_id, :accepted_web_push_subscription], where: "((accepted_web_push_subscription IS TRUE) AND (web_push_subscription_popup_showed IS TRUE))"
    add_index :clients, [:shop_id, :web_push_subscription_popup_showed], where: "(web_push_subscription_popup_showed IS TRUE)"
  end
end
