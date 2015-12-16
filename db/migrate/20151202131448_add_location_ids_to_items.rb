class AddLocationIdsToItems < ActiveRecord::Migration
  def change
    add_column :items, :location_ids, :string, array: true
  end
end
