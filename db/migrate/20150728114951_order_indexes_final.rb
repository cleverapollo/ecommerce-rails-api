class OrderIndexesFinal < ActiveRecord::Migration
  def change
    remove_index :orders, name: :index_orders_on_shop_id_and_uniqid
    add_index :orders, [:shop_id, :uniqid], unique: true
    add_index :orders, [:uniqid]
    add_index :orders, [:source_type, :source_id]

    add_index "items", ["shop_id"], where: "widgetable=true AND is_available = true AND ignored = false", using: :btree, name: "widgetable_shop"
  end
end
