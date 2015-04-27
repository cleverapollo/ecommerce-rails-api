class RemoveItemsAndAmountsFromOrders < ActiveRecord::Migration
  def change
    remove_column :orders, :items
    remove_column :orders, :amounts
  end
end
