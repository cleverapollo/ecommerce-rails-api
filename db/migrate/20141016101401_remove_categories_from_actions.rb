class RemoveCategoriesFromActions < ActiveRecord::Migration
  def change
    remove_column :actions, :categories
  end
end
