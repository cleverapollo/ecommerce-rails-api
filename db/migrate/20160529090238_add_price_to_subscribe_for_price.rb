class AddPriceToSubscribeForPrice < ActiveRecord::Migration
  def change
    add_column :subscribe_for_product_prices, :price, :decimal, null: false
  end
end
