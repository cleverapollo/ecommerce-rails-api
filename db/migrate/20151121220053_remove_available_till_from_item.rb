class RemoveAvailableTillFromItem < ActiveRecord::Migration
  def change
    remove_column :items, :available_till
  end
end
