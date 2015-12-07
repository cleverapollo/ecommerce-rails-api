class RemoveUniqIdShopIdIndex < ActiveRecord::Migration
  def change
    remove_index :items, name: 'items_uniqid_shop_id_key'
  end
end
