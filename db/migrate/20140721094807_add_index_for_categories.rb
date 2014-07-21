class AddIndexForCategories < ActiveRecord::Migration
  def change
    execute <<-SQL
      create index popular_index on actions using gin (shop_id, "timestamp", categories) WHERE is_available = true AND purchase_count > 0;
    SQL
  end
end
