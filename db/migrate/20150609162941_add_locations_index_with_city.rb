class AddLocationsIndexWithCity < ActiveRecord::Migration
  def change
    add_index "items", ["shop_id", "locations"], name: "index_items_on_locations_and_shop_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  end
end
