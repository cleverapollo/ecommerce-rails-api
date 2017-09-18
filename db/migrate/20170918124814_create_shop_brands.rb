class CreateShopBrands < ActiveRecord::Migration
  def change
    create_table :shop_brands do |t|
      t.string :brand
      t.integer :popularity, null: false, default: 0
      t.integer :shop_id
      t.timestamps null: false
    end
    add_index :shop_brands, :shop_id
  end
end
