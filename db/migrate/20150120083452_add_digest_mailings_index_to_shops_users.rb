class AddDigestMailingsIndexToShopsUsers < ActiveRecord::Migration
  def change
    add_index :shops_users, :shop_id, where: 'email IS NOT NULL AND digests_enabled = true'
  end
end
