class AddIndustrialFlagsToItem < ActiveRecord::Migration
  def change
    add_column :items, :is_cosmetic, :boolean
    add_column :items, :is_child, :boolean
    add_column :items, :is_fashion, :boolean
    add_index "items", ["is_cosmetic"], where: "((is_available = true) AND (ignored = false))"
    add_index "items", ["is_child"], where: "((is_available = true) AND (ignored = false))"
    add_index "items", ["is_fashion"], where: "((is_available = true) AND (ignored = false))"
  end
end
