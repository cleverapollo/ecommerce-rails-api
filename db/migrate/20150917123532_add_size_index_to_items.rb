class AddSizeIndexToItems < ActiveRecord::Migration
  def change
    add_index "items", ["sizes"], name: :index_items_on_sizes_recommendable, where: "((is_available = true) AND (ignored = false))", using: :gin
  end
end
