class RemoveCategoryUniqidFromItemsAndActions < ActiveRecord::Migration
  def change
    remove_column :actions, :category_uniqid
    remove_column :items, :category_uniqid
  end
end
