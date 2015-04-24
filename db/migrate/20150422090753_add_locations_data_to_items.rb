class AddLocationsDataToItems < ActiveRecord::Migration
  def change
    add_column :items, :locations_data, :jsonb, default: '{}', null: false
    add_index :items, :locations_data, using: :gin
  end
end
