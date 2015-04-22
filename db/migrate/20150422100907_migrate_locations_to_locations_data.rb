class MigrateLocationsToLocationsData < ActiveRecord::Migration
  def change
    Item.where("locations != '{}'").where('shop_id NOT IN (?)', [114, 146]).find_each do |item|
      item.locations.each do |location|
        item.locations_data[location] = {}
      end
      item.locations = []
      item.save
    end

    remove_column :items, :locations
  end
end
