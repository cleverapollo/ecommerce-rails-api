class DropUnneededLocationsIndex < ActiveRecord::Migration
  def change
    remove_index :items, name: :index_items_on_locations_and_shop_recommendable
  end
end
