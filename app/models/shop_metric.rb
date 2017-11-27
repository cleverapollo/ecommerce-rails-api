class ShopMetric < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, :date, presence: true
  validates :orders, :real_orders, :revenue, :real_revenue, :visitors, :products_viewed, :triggers_enabled_count, :triggers_orders, :triggers_revenue, :digests_revenue, :digests_orders, :abandoned_money, :abandoned_products, :triggers_sent, :triggers_clicked, :triggers_revenue_real, :triggers_orders_real, :digests_sent, :digests_clicked, :digests_revenue_real, :digests_orders_real, :subscription_accepted, :subscription_popup_showed, :orders_original_count, :orders_original_revenue, :orders_recommended_count, :orders_recommended_revenue, :product_views_total, :product_views_recommended, :web_push_subscription_popup_showed, :web_push_subscription_permission_showed, :web_push_subscription_accepted, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
