class AddMoreIndices < ActiveRecord::Migration
  def change
    add_index :user_shop_relations, :user_id
    add_index :orders, :uniqid
  end
end
