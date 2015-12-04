class AddCategoryIdsToItems < ActiveRecord::Migration
  def change
    add_column :items, :category_ids, :string, array: true
  end
end
