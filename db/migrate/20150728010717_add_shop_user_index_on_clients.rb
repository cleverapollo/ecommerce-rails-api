class AddShopUserIndexOnClients < ActiveRecord::Migration
  def change
    add_index :clients, [:shop_id, :user_id]
  end
end
