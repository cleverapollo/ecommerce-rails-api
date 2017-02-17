class AddJewelryToItems < ActiveRecord::Migration
  def change
    add_column :items, :is_jewelry, :boolean
    add_column :items, :jewelry_gender, :string
    add_column :items, :jewelry_color, :string
    add_column :items, :jewelry_metal, :string
    add_column :items, :jewelry_gem, :string
    add_column :items, :ring_sizes, :jsonb
    add_column :items, :bracelet_sizes, :jsonb
    add_column :items, :chain_sizes, :jsonb

    add_index :items, :jewelry_gender, where: "is_jewelry IS TRUE AND jewelry_gender IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :jewelry_color, where: "is_jewelry IS TRUE AND jewelry_color IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :jewelry_metal, where: "is_jewelry IS TRUE AND jewelry_metal IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :jewelry_gem, where: "is_jewelry IS TRUE AND jewelry_gem IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :ring_sizes, where: "is_jewelry IS TRUE AND ring_sizes IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :bracelet_sizes, where: "is_jewelry IS TRUE AND bracelet_sizes IS NOT NULL AND is_available = true AND ignored = false", using: :btree
    add_index :items, :chain_sizes, where: "is_jewelry IS TRUE AND chain_sizes IS NOT NULL AND is_available = true AND ignored = false", using: :btree

  end
end
