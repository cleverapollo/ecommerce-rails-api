class AddIndexItemPrice < ActiveRecord::Migration
  def change
    add_index :items, :price, where: "((is_available = true) AND (ignored = false))"
  end
end
