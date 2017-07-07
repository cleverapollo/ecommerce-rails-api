# Класс отвечающий за партиции таблиц: sessions
# @see https://habrahabr.ru/company/oleg-bunin/blog/309330/
# @deprecated
class DataManager::Partition::Session

  class << self

    # Проверяет партиции таблицы sessions. При необходимости создает новые партиции.
    def check
      ActiveRecord::Base.logger.level = 0

      # Сколько должно быть партиций (создаем на 1 больше)
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{table_name(i)} (
            LIKE sessions INCLUDING ALL,
            CHECK ( abs(hashtext(code)) % 10 = #{i} )
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
            i := abs(hashtext(NEW.code)) % 10;
            in_table := format('sessions_%s', i);
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
      min = Session.connection.select_value('SELECT min(id) FROM sessions_master WHERE updated_at IS NOT NULL').to_i
      max = Session.connection.select_value('SELECT max(id) FROM sessions_master WHERE updated_at IS NOT NULL').to_i
      step = 10000
      (((min / step).to_i * step)..max).step(step) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from sessions_master where id < #{(n + step)} AND id >= #{n} AND updated_at IS NOT NULL returning * ) insert into sessions select * from moved_rows;"
        STDOUT.write "\r#{n}"
        sleep(5) if n % 100000 == 0
      end
      STDOUT.write "\n"
    end

    # Перемещает данные обратно в основную таблицу
    # @param [String] table Таблица, из которой нужно перенести
    def move_to_root(table)
      # Удаляем правило вставки в партиции (если оно есть)
      ActiveRecord::Base.connection.execute 'DROP RULE IF EXISTS sessions_insert ON sessions'

      min = Session.connection.select_value("SELECT min(id) FROM #{table}").to_i
      max = Session.connection.select_value("SELECT max(id) FROM #{table}").to_i
      step = 5000
      (min..max).step(step) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from #{table} where id < #{(n + step)} AND id >= #{n} returning * ) insert into sessions select * from moved_rows;"
        STDOUT.write "\r#{n}"
      end
      STDOUT.write "\n"
    end

    private

    # Сколько должно быть партиций
    def partitions_size
      10
    end

    # Имя таблицы для партиции
    def table_name(i)
      "sessions_#{i % 10}"
    end

  end

end
