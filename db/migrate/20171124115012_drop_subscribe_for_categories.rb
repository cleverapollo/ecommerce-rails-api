class DropSubscribeForCategories < ActiveRecord::Migration
  def change
    drop_table :subscribe_for_categories
  end
end
