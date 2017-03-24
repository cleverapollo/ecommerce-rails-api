class AddIndexForItemsUpdate < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :items, [:shop_id, :uniqid], where: 'is_available = true', name: 'index_items_on_shop_id_and_uniqid_and_is_available', algorithm: :concurrently;
  end
end
