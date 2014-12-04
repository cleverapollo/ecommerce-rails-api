class RemoveIsAvailableFromActions < ActiveRecord::Migration
  def change
    remove_column :actions, :is_available

    add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_purchases", where: "(purchase_count > 0)", using: :btree
    add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_rating", using: :btree
    add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", using: :btree
  end
end
