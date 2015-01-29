class DropActionsBool < ActiveRecord::Migration
  def change
    drop_table :actions_bool
  end
end
