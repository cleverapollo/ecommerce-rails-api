class AddPeriodicToItems < ActiveRecord::Migration
  def change
    add_column :items, :periodic, :boolean
  end
end
