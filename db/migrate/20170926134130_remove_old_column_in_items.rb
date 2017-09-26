class RemoveOldColumnInItems < ActiveRecord::Migration
  def change
    remove_column :items, :part_type
    remove_column :items, :skin_type
    remove_column :items, :condition
  end
end
