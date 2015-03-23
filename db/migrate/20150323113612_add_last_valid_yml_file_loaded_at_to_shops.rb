class AddLastValidYmlFileLoadedAtToShops < ActiveRecord::Migration
  def change
    add_column :shops, :last_valid_yml_file_loaded_at, :timestamp
  end
end
