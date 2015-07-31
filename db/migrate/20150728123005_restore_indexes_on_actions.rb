class RestoreIndexesOnActions < ActiveRecord::Migration
  def change
    add_index :actions, [:shop_id, :item_id, :timestamp], where: "purchase_count > 0", name: "popular_index_by_purchases"
    add_index :actions, [:shop_id, :item_id, :timestamp], name: "popular_index_by_rating"

  end
end
