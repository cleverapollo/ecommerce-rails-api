class ChangeItemCategoryParentIdLength < ActiveRecord::Migration
  def change
    change_column :item_categories, :parent_id, :integer, limit: 8
  end
end
