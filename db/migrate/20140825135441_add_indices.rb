class AddIndices < ActiveRecord::Migration
  def change
    add_index :shops_users, :user_id
    add_index :interactions, :user_id
  end
end
