class AddPopularIndices < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP INDEX popular_index;
      DROP INDEX popular_index_rating;
    SQL

    execute <<-SQL
      CREATE INDEX popular_index ON actions (shop_id, item_id, "timestamp") WHERE purchase_count > 0;
    SQL

    execute <<-SQL
      CREATE INDEX shop_available_index ON items (shop_id) WHERE is_available = true;
    SQL


  end
end
