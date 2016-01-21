class AddTaxonomyToItemCategory < ActiveRecord::Migration
  def change
    add_column :item_categories, :taxonomy, :string
    add_index :item_categories, [:shop_id], where: 'taxonomy is not null', name: :index_item_categories_with_taxonomy
    add_index :item_categories, [:shop_id], where: 'taxonomy is null and name is not null', name: :index_item_categories_without_taxonomy
  end
end
