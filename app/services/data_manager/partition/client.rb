# Класс отвечающий за партиции таблиц: clients
# @see https://habrahabr.ru/company/oleg-bunin/blog/309330/
class DataManager::Partition::Client

  # Количество строк в партиции
  # !!! НЕ ИЗМЕНЯТЬ !!! Если на проде уже созданы партиции
  PACK = 1000

  class << self

    # Проверяет партиции таблицы clients. При необходимости создает новые партиции.
    def check
      ActiveRecord::Base.logger.level = 0

      # Сколько должно быть партиций (создаем на 1 больше)
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{table_name(i)} (
            LIKE clients INCLUDING ALL,
            CHECK ( shop_id > #{i * PACK} AND shop_id <= #{(i + 1) * PACK} )
          ) INHERITS (clients);
        SQL
      end

      # Создаем триггер, который определяет, куда ему вставлять данные
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE OR REPLACE FUNCTION clients_insert_to(new clients) RETURNS bigint AS $$
          DECLARE in_table text;
          DECLARE i int;
          DECLARE result bigint;
          BEGIN
            i := ceil(NEW.shop_id::float / #{PACK}) - 1;
            in_table := format('clients_%s', i);
            EXECUTE 'INSERT INTO ' || in_table || ' VALUES ( ($1).* ) ' USING NEW;
            RETURN NEW.id;
          END;
        $$ LANGUAGE plpgsql;
        CREATE OR REPLACE RULE clients_insert AS ON INSERT TO clients DO INSTEAD ( SELECT clients_insert_to(NEW) );
      SQL
    end

    # !!! Удаляет все партиции таблицы clients
    def drop_partitions
      ActiveRecord::Base.logger.level = 0
      ActiveRecord::Base.connection.execute <<-SQL
        DROP RULE IF EXISTS clients_insert ON clients;
        DROP FUNCTION IF EXISTS clients_insert_to();
      SQL
      partitions_size.times do |i|
        ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table_name(i)} CASCADE"
      end
    end

    # Переносит юзеров с мастер таблицы в партиции
    def move_from_root
      min = Client.connection.select_value('SELECT min(id) FROM ONLY clients').to_i
      max = Client.connection.select_value('SELECT max(id) FROM ONLY clients').to_i
      step = 1000
      (((min / step).to_i * step)..max).step(step) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete FROM ONLY clients where id < #{(n + step)} AND id >= #{n} returning * ) insert into clients select * from moved_rows;"
        STDOUT.write "\r#{n}"
        sleep(2) if n % 5000000 == 0
      end
      STDOUT.write "\n"
    end

    # Перемещает данные обратно в основную таблицу
    # @param [String] table Таблица, из которой нужно перенести
    def move_to_root(table)
      # Удаляем правило вставки в партиции (если оно есть)
      ActiveRecord::Base.connection.execute 'DROP RULE IF EXISTS clients_insert ON clients'

      min = Client.connection.select_value("SELECT min(id) FROM #{table}").to_i
      max = Client.connection.select_value("SELECT max(id) FROM #{table}").to_i
      step = 1000
      (min..max).step(step) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from #{table} where id < #{(n + step)} AND id >= #{n} returning * ) insert into clients select * from moved_rows;"
        STDOUT.write "\r#{n}"
      end
      STDOUT.write "\n"
    end

    private

    # Сколько должно быть партиций
    def partitions_size
      (Shop.maximum(:id).to_f / PACK).ceil.to_i + 1
    end

    # Имя таблицы для партиции
    def table_name(i)
      "clients_#{i}"
    end

  end

end
