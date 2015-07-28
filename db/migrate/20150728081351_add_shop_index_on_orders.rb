class AddShopIndexOnOrders < ActiveRecord::Migration
  def change
    add_index :orders, :shop_id
  end
end
