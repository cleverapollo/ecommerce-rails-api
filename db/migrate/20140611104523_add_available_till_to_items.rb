class AddAvailableTillToItems < ActiveRecord::Migration
  def change
    add_column :items, :available_till, :date
  end
end
