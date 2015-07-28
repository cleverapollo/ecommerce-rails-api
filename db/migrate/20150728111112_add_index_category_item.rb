class AddIndexCategoryItem < ActiveRecord::Migration
  def change
    add_index "items", ["categories"], name: :index_items_on_categories, using: :gin
    add_index "items", ["categories"], name: :index_items_on_categories_recommendable, where: "((is_available = true) AND (ignored = false))", using: :gin
  end
end
