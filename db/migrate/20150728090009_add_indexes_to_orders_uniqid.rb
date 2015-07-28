class AddIndexesToOrdersUniqid < ActiveRecord::Migration
  def change
    add_index :orders, [:shop_id, :uniqid]
    add_index :orders, :user_id
  end
end
