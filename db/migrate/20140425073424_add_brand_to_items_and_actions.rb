class AddBrandToItemsAndActions < ActiveRecord::Migration
  def change
    add_column :actions, :brand, :string
    add_column :items, :brand, :string
  end
end
