class AddItemIdIndexToOrderItems < ActiveRecord::Migration
  def change
    add_index :order_items, :item_id
  end
end
