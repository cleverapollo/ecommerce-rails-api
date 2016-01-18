class UpdateSizesIndexOnItems < ActiveRecord::Migration
  def change
    remove_column :items, :sizes
    add_column :items, :sizes, :string, array: true
    add_index "items", ["sizes", "wear_type"], name: :index_items_on_sizes_recommendable, where: "((is_available IS true) AND (ignored IS false)) AND ( sizes IS NOT NULL AND wear_type IS NOT NULL )", using: :gin
  end
end
