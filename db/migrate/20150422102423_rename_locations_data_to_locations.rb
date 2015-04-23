class RenameLocationsDataToLocations < ActiveRecord::Migration
  def change
    rename_column :items, :locations_data, :locations
  end
end
