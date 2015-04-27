class RemoveConnectionStatusFromShops < ActiveRecord::Migration
  def change
    remove_column :shops, :connection_status
  end
end
