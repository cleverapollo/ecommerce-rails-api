class MergeUserShopRelationsIntoShopsUsers < ActiveRecord::Migration
  def change
    add_column :shops_users, :id, :primary_key
    add_column :shops_users, :external_id, :string
    add_column :shops_users, :email, :string
    add_index :shops_users, [:shop_id, :external_id], unique: true
  end
end
