class CreateDigestMailingsLaunchIndexOnShopsUsers < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    execute <<-SQL
      CREATE INDEX CONCURRENTLY ON shops_users (shop_id, id ASC) where email IS NOT NULL AND digests_enabled = true;
    SQL
  end
end
