class DropInheritsUserTable < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP FOREIGN TABLE IF EXISTS users_1 CASCADE;
    SQL
  end

  def down

  end
end
