# Класс отвечающий за партиции таблиц: sessions
# @see https://habrahabr.ru/company/oleg-bunin/blog/309330/
class DataManager::Partition::Session

  # Количество строк в партиции
  # !!! НЕ ИЗМЕНЯТЬ !!! Если на проде уже созданы партиции
  PACK = 100_000_000

  class << self

    # Проверяет партиции таблицы sessions. При необходимости создает новые партиции.
    def check
      ActiveRecord::Base.logger.level = 0

      # Сколько должно быть партиций (создаем на 1 больше)
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{table_name(i)} (
            LIKE sessions INCLUDING ALL,
            CHECK ( id > #{i * PACK} AND id <= #{(i + 1) * PACK} )
          ) INHERITS (sessions);
        SQL
      end

      # Создаем триггер, который определяет, куда ему вставлять данные
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE OR REPLACE FUNCTION sessions_insert_to(new sessions) RETURNS bigint AS $$
          DECLARE in_table text;
          DECLARE i int;
          DECLARE result bigint;
          BEGIN
            i := (ceil(NEW.id::float / #{PACK}) - 1) * 100;
            in_table := format('sessions_%s_%s', i, i + 100);
            EXECUTE 'INSERT INTO ' || in_table || ' VALUES ( ($1).* ) ' USING NEW;
            RETURN NEW.id;
          END;
        $$ LANGUAGE plpgsql;
        CREATE OR REPLACE RULE sessions_insert AS ON INSERT TO sessions DO INSTEAD ( SELECT sessions_insert_to(NEW) );
      SQL
    end

    # !!! Удаляет все партиции таблицы sessions
    def drop_partitions
      ActiveRecord::Base.logger.level = 0
      ActiveRecord::Base.connection.execute <<-SQL
        DROP RULE IF EXISTS sessions_insert ON sessions;
        DROP FUNCTION IF EXISTS sessions_insert_to();
      SQL
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table_name(i)} CASCADE"
      end
    end

    # Переносит юзеров с мастера на шард
    def move_from_master
      min = Session.connection.select_value('SELECT min(id) FROM sessions_master').to_i
      max = Session.connection.select_value('SELECT max(id) FROM sessions_master').to_i
      (min..max).step(5000) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from sessions_master where id < #{(n + 5000)} AND updated_at IS NOT NULL returning * ) insert into sessions select * from moved_rows;"
        STDOUT.write "\r#{n}"
      end
      STDOUT.write "\n"
    end

    private

    # Сколько должно быть партиций
    def partitions_size
      (Session.maximum(:id).to_f / PACK).ceil.to_i + 1
    end

    # Имя таблицы для партиции
    def table_name(i)
      "sessions_#{(i.to_f * PACK / (PACK / 100)).round.to_i}_#{(((i + 1).to_f * PACK) / (PACK / 100)).round.to_i}"
    end

  end

end
