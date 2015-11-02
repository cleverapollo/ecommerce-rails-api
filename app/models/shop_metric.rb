class ShopMetric < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, :date, presence: true
  validates :orders, :real_orders, :revenue, :real_revenue, :orders_quality, :arpu, :arppu, :conversion, :visitors, :products_viewed, :triggers_enabled_count, :triggers_ctr, :triggers_orders, :triggers_revenue, :digests_revenue, :digests_ctr, :digests_orders, :abandoned_money, :abandoned_products, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
