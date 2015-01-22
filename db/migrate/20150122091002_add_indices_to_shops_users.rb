class AddIndicesToShopsUsers < ActiveRecord::Migration
  def change
    remove_index :shops_users, name: 'index_shops_users_on_shop_id'
    add_index :shops_users, :email
    add_index :shops_users, :shop_id
    add_index :shops_users, [:subscription_popup_showed, :shop_id]
    add_index :shops_users, [:digests_enabled, :shop_id]
    add_index :shops_users, [:triggers_enabled, :shop_id]
    add_index :shops_users, [:accepted_subscription, :shop_id], where: 'subscription_popup_showed = true'
  end
end
