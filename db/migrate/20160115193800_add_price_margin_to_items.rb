class AddPriceMarginToItems < ActiveRecord::Migration
  def change
    add_column :items, :price_margin, :integer
    add_index :items, [:shop_id, :price_margin, :sales_rate], where: 'price_margin is not null and is_available is true and ignored is false'
  end
end
