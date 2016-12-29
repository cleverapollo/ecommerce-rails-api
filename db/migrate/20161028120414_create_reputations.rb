class CreateReputations < ActiveRecord::Migration
  def up
    create_table :reputations, id: :bigserial do |t|
      t.string :name
      t.integer :rating
      t.text :plus
      t.text :minus
      t.text :comment
      t.datetime :published_at
      t.references :shop, index: true
      t.integer  :entity_id, limit: 8
      t.string   :entity_type
      t.integer :parent_id, index: true, limit: 8
      t.timestamps null: false
    end

    add_index "reputations", ["entity_type", "entity_id"], name: "index_reputations_on_entity_type_and_entity_id", using: :btree

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_reputations_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('reputations_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE reputations ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE reputations ALTER COLUMN id SET DEFAULT generate_next_reputations_id();
      ALTER TABLE reputations ALTER COLUMN id SET NOT NULL;
    SQL
  end

  def down
    drop_table :reputations
    execute <<-SQL
      DROP FUNCTION IF EXISTS generate_next_reputations_id(OUT result bigint);
    SQL
  end
end
