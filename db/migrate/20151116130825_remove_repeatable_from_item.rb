class RemoveRepeatableFromItem < ActiveRecord::Migration
  def change
    remove_column :items, :repeatable
  end
end
