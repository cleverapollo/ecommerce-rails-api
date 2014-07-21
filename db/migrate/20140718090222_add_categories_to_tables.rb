class AddCategoriesToTables < ActiveRecord::Migration
  def change
    add_column :items, :categories, :string, array: true, default: []
    add_column :actions, :categories, :string, array: true, default: []
  end
end
