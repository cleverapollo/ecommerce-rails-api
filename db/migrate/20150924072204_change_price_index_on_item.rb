class ChangePriceIndexOnItem < ActiveRecord::Migration
  def change
    remove_index :items, name: :index_items_on_price
    add_index "items", ["price"], name: "index_items_on_price", where: "((is_available = true) AND (ignored = false) AND (price IS NOT NULL))", using: :btree
  end
end
