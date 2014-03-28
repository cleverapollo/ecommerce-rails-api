class CreateMahoutActions < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE mahout_actions AS
        SELECT user_id, item_id, shop_id, timestamp from actions
        WHERE rating >= 3.7
    SQL

    execute <<-SQL
      ALTER TABLE mahout_actions ADD COLUMN id SERIAL PRIMARY KEY;
    SQL

    add_index :mahout_actions, :shop_id
    add_index :mahout_actions, [:user_id, :item_id], unique: true
  end

  def down
    execute <<-SQL
      DROP TABLE mahout_actions
    SQL
  end
end
