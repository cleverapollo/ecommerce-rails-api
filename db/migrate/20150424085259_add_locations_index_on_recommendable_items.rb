class AddLocationsIndexOnRecommendableItems < ActiveRecord::Migration
  def change
    add_index :items, :locations, name: 'index_items_on_locations_recommendable', using: :gin, where: 'is_available = true AND ignored = false'
  end
end
