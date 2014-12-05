class AddIgnoredToItems < ActiveRecord::Migration
  def change
    add_column :items, :ignored, :boolean, default: false, null: false
    execute <<-SQL
      DROP INDEX shop_available_index;
      CREATE INDEX shop_available_index ON items (shop_id) WHERE (is_available = true AND ignored = false);
    SQL
  end
end
