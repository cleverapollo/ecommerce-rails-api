class AddRepeatableToItemsAndActions < ActiveRecord::Migration
  def change
    add_column :items, :repeatable, :boolean, default: false, null: false
    add_column :actions, :repeatable, :boolean, default: false, null: false
  end
end
