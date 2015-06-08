class OptimizeItemBrandIndex < ActiveRecord::Migration
  def change
    remove_index :items, :brand
    add_index :items, :brand, where: 'brand IS NOT NULL'
  end
end
