class DataSchemaRework < ActiveRecord::Migration
  def change
    change_column :items, :is_available, :boolean, null: false, default: true

    change_table :actions do |t|
      t.boolean :is_available, null: false, default: true
      t.string :category_uniqid
    end

    execute <<-SQL
      UPDATE actions
      SET
        category_uniqid = items.category_uniqid,
        is_available = items.is_available
      FROM items
      WHERE actions.item_id = items.id;
    SQL

    execute <<-SQL
      CREATE INDEX ON actions (shop_id, is_available, "timestamp", category_uniqid);
    SQL
  end
end
