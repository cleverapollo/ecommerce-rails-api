class CreateShopLocations < ShardMigration
  def change
    create_table :shop_locations do |t|
      t.integer :shop_id, null: false
      t.string :external_id, null: false
      t.string :name, null: false
      t.string :external_type, null: false
      t.integer :parent_id, limit: 8
      t.string :parent_external_id

      t.timestamps null: false
    end

    add_index :shop_locations, [:shop_id, :external_id], unique: true
  end
end
