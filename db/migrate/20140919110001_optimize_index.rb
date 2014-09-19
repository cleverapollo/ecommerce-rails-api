class OptimizeIndex < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP INDEX actions_shop_id_is_available_timestamp_category_uniqid_idx;
      CREATE INDEX buying_now_index ON actions (shop_id, "timestamp") WHERE is_available = true;
    SQL
  end
end
