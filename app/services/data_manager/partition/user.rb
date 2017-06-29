# Класс отвечающий за партиции таблиц: users, sessions
# @see https://habrahabr.ru/company/oleg-bunin/blog/309330/
class DataManager::Partition::User

  # Количество строк в партиции
  # !!! НЕ ИЗМЕНЯТЬ !!! Если на проде уже созданы партиции
  PACK = 100_000_000

  class << self

    # Проверяет партиции таблицы users. При необходимости создает новые партиции.
    def check
      ActiveRecord::Base.logger.level = 0

      # Сколько должно быть партиций (создаем на 1 больше)
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{table_name(i)} (
            LIKE users INCLUDING ALL,
            CHECK ( id > #{i * PACK} AND id <= #{(i + 1) * PACK} )
          ) INHERITS (users);
        SQL
      end

      # Создаем триггер, который определяет, куда ему вставлять данные
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE OR REPLACE FUNCTION users_insert_to(new users) RETURNS bigint AS $$
          DECLARE in_table text;
          DECLARE i int;
          DECLARE result bigint;
          BEGIN
            i := floor(NEW.id::float / #{PACK}) * 100;
            in_table := format('users_%s_%s', i, i + 100);
            EXECUTE 'INSERT INTO ' || in_table || ' VALUES ( ($1).* ) ' USING NEW;
            RETURN NEW.id;
          END;
        $$ LANGUAGE plpgsql;
        CREATE OR REPLACE RULE users_insert AS ON INSERT TO users DO INSTEAD ( SELECT users_insert_to(NEW) );
      SQL
    end

    # !!! Удаляет все партиции таблицы users
    def drop_partitions
      ActiveRecord::Base.logger.level = 0
      User.connection.empty_insert_statement_value
      ActiveRecord::Base.connection.execute <<-SQL
        DROP RULE IF EXISTS users_insert ON users;
        DROP FUNCTION IF EXISTS users_insert_to();
      SQL
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table_name(i)} CASCADE"
      end
    end

    private

    # Сколько должно быть партиций
    def partitions_size
      (User.maximum(:id).to_f / PACK).ceil.to_i + 1
    end

    # Имя таблицы для партиции
    def table_name(i)
      "users_#{(i.to_f * PACK / (PACK / 100)).round.to_i}_#{(((i + 1).to_f * PACK) / (PACK / 100)).round.to_i}"
    end

  end

end
