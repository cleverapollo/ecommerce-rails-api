class RenameObsoleteCategoriesBeforeDelete < ActiveRecord::Migration
  def change
    rename_column :items, :categories, :old_fucking_categories
    add_index "items", ["category_ids"], using: :gin
    add_index "items", ["category_ids"], name: 'index_items_on_category_ids_recommendable', where: "((is_available = true) AND (ignored = false))", using: :gin
  end
end
