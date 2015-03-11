class CreateItemCategories < ActiveRecord::Migration
  def change
    create_table :item_categories do |t|
      t.integer :shop_id, null: false
      t.integer :parent_id
      t.string :external_id, null: false
      t.string :parent_external_id
      t.string :name

      t.timestamps null: false
    end

    add_index :item_categories, [:shop_id, :external_id], unique: true
  end
end
