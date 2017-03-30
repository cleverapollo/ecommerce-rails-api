class DropUnusableItemsIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :items, name: 'index_items_on_is_cosmetic'
    remove_index :items, name: 'index_items_on_is_child'
    remove_index :items, name: 'index_items_on_is_fashion'
    remove_index :items, name: 'index_items_on_is_pets'
    remove_index :items, name: 'index_items_on_is_auto'
  end
  def down
    add_index :items, [:is_auto], name: 'index_items_on_is_auto', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
    add_index :items, [:is_child], name: 'index_items_on_is_child', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
    add_index :items, [:is_cosmetic], name: 'index_items_on_is_cosmetic', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
    add_index :items, [:is_fashion], name: 'index_items_on_is_fashion', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
    add_index :items, [:is_pets], name: 'index_items_on_is_pets', where: '((is_available = true) AND (ignored = false))', algorithm: :concurrently
  end
end
