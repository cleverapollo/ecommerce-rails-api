class ChangePopularIndex < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP INDEX popular_index;
      DROP INDEX tmpidx1;
      DROP INDEX tmpidx2;
    SQL

    execute <<-SQL
      CREATE INDEX popular_index_by_purchases ON actions (shop_id, item_id, "timestamp") WHERE purchase_count > 0 AND is_available = true;
      CREATE INDEX popular_index_by_rating ON actions (shop_id, item_id, "timestamp") WHERE is_available = true;
    SQL
  end
end
