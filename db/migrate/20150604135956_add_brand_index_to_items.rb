class AddBrandIndexToItems < ActiveRecord::Migration
  def change
    add_index :items, :brand
  end
end
