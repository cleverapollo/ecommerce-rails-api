class AddLocationsToItemsAndActions < ActiveRecord::Migration
  def change
    add_column :items, :locations, :string, array: true, default: '{}'
    add_column :actions, :locations, :string, array: true, default: '{}'
  end
end
