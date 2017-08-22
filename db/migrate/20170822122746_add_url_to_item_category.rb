class AddUrlToItemCategory < ActiveRecord::Migration
  def change
    add_column :item_categories, :url, :string
    add_index :item_categories, [:shop_id, :url], name: 'index_item_categories_with_url', where: 'url IS NOT NULL'
  end
end
