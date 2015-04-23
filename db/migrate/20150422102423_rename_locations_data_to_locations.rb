class RenameLocationsDataToLocations < ActiveRecord::Migration
  def change
    remove_column :items, :locations
    rename_column :items, :locations_data, :locations
  end
end
