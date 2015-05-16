class AddSalesRateToItem < ActiveRecord::Migration
  def change
    add_column :items, :sales_rate, :integer, limit: 2
    add_index 'items', ['shop_id', 'sales_rate'], name: "available_items_with_sales_rate", where: "((is_available = true) AND (ignored = false) AND (sales_rate IS NOT NULL) AND (sales_rate > 0))", using: :btree
  end
end
