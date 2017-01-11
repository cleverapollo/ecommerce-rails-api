class CreateShopThemes < ActiveRecord::Migration
  def up
    create_table :shop_themes do |t|
      t.string :name, null: false
      t.integer :theme_id, null: false
      t.references :shop, index: true
      t.string :theme_type, null: false
      t.jsonb :variables
      t.text :compiled_css
      t.boolean :is_custom, null: false, default: false

      t.timestamps null: false
    end

    add_index :shop_themes, [:shop_id, :theme_type], name: 'index_shop_themes_on_shop_id_and_theme_type', using: :btree

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_shop_themes_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('shop_themes_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE shop_themes ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE shop_themes ALTER COLUMN id SET DEFAULT generate_next_shop_themes_id();
      ALTER TABLE shop_themes ALTER COLUMN id SET NOT NULL;
    SQL
  end

  def down
    drop_table :shop_themes
    execute <<-SQL
      DROP FUNCTION IF EXISTS generate_next_shop_themes_id(OUT result bigint);
    SQL
  end
end
