class AddIndicesToShopsUsers < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    remove_index :shops_users, name: 'index_shops_users_on_shop_id', column: :shop_id, where: 'email IS NOT NULL'
    add_index :shops_users, :email, algorithm: :concurrently
    add_index :shops_users, :shop_id, algorithm: :concurrently
    add_index :shops_users, [:subscription_popup_showed, :shop_id], algorithm: :concurrently
    add_index :shops_users, [:digests_enabled, :shop_id], algorithm: :concurrently
    add_index :shops_users, [:triggers_enabled, :shop_id], algorithm: :concurrently
    add_index :shops_users, [:accepted_subscription, :shop_id], where: 'subscription_popup_showed = true', algorithm: :concurrently
  end
end
