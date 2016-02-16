class RemoveRepeatableFromAction < ActiveRecord::Migration
  def change
    remove_column :actions, :repeatable
  end
end
