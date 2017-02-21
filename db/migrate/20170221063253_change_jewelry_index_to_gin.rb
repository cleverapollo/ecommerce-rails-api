class ChangeJewelryIndexToGin < ActiveRecord::Migration
  def up
    remove_index :items, name: :index_items_on_bracelet_sizes
    remove_index :items, name: :index_items_on_chain_sizes
    remove_index :items, name: :index_items_on_ring_sizes
    connection.execute 'CREATE  INDEX  "index_items_on_ring_sizes" ON "items" USING gin (ring_sizes jsonb_path_ops) WHERE is_available = true AND ignored = false AND is_jewelry IS TRUE AND ring_sizes IS NOT NULL'
    connection.execute 'CREATE  INDEX  "index_items_on_bracelet_sizes" ON "items" USING gin (bracelet_sizes jsonb_path_ops) WHERE is_available = true AND ignored = false AND is_jewelry IS TRUE AND bracelet_sizes IS NOT NULL'
    connection.execute 'CREATE  INDEX  "index_items_on_chain_sizes" ON "items" USING gin (chain_sizes jsonb_path_ops) WHERE is_available = true AND ignored = false AND is_jewelry IS TRUE AND chain_sizes IS NOT NULL'
  end

  def down
    remove_index :items, name: :index_items_on_bracelet_sizes
    remove_index :items, name: :index_items_on_chain_sizes
    remove_index :items, name: :index_items_on_ring_sizes
    add_index "items", ["bracelet_sizes"], name: "index_items_on_bracelet_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (bracelet_sizes IS NOT NULL))", using: :gin
    add_index "items", ["chain_sizes"], name: "index_items_on_chain_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (chain_sizes IS NOT NULL))", using: :gin
    add_index "items", ["ring_sizes"], name: "index_items_on_ring_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (ring_sizes IS NOT NULL))", using: :gin
  end

end
