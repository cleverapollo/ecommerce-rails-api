class RemoveLocationsFromActions < ActiveRecord::Migration
  def change
    remove_column :actions, :locations
  end
end
