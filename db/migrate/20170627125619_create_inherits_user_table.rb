class CreateInheritsUserTable < ActiveRecord::Migration

  def up

    # Создаем внешнюю таблицу с мастера
    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    config = ActiveRecord::Base.configurations["#{Rails.env}"]

    if Rails.env.development?
      execute <<-SQL
        CREATE EXTENSION IF NOT EXISTS postgres_fdw;
        CREATE SERVER master_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '#{config_master["host"] == "localhost" ? "127.0.0.1" : config_master["host"]}', port '#{config_master["port"] || 5432}', dbname '#{config_master["database"]}');
        CREATE USER MAPPING FOR #{config['username']} SERVER master_server OPTIONS (user '#{config_master["username"]}', password '#{config_master["password"]}');
      SQL
    end

    execute <<-SQL
      CREATE FOREIGN TABLE users_1 (
        "id" bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
        "gender" varchar(1) COLLATE "default",
        "fashion_sizes" jsonb,
        "allergy" bool,
        "cosmetic_hair" jsonb,
        "cosmetic_skin" jsonb,
        "children" jsonb,
        "compatibility" jsonb,
        "vds" jsonb,
        "pets" jsonb,
        "jewelry" jsonb,
        "cosmetic_perfume" jsonb
      ) SERVER master_server OPTIONS (table_name 'users');
      ALTER TABLE users_1 INHERIT users;
      SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users) + 1000, 1), false);
    SQL
    execute "ALTER TABLE users_1 ADD CONSTRAINT master_check CHECK ( id < #{User.maximum(:id)} )"
  end

  def down
    config = ActiveRecord::Base.configurations["#{Rails.env}"]
    execute <<-SQL
      DROP FOREIGN TABLE users_1 CASCADE;
    SQL

    if Rails.env.development?
      execute <<-SQL
        DROP USER MAPPING FOR #{config['username']} SERVER master_server;
        DROP SERVER master_server;
      SQL
    end
  end
end
