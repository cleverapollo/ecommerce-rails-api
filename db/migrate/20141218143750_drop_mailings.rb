class DropMailings < ActiveRecord::Migration
  def change
    drop_table :mailings
  end
end
