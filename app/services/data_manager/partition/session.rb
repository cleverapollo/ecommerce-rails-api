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
            CHECK ( abs(hashtext(code)) % #{partitions_size} = #{i} )
          ) INHERITS (sessions);
        SQL
      end

      # Создаем триггер, который определяет, куда ему вставлять данные
      ActiveRecord::Base.connection.execute <<-SQL
        CREATE OR REPLACE FUNCTION sessions_insert_to(new sessions) RETURNS bigint AS $$
          DECLARE in_table text;
          DECLARE i int;
          BEGIN
            i := abs(hashtext(NEW.code)) % #{partitions_size};
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
      batch = 1000
      n = 0
      Session.from('sessions_master as sessions').select('sessions.id').find_in_batches(batch_size: batch) do |group|
        ids = group.map(&:id)
        n += ids.size
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete from sessions_master where id IN (#{ids.join(',')}) returning * ) insert into sessions select * from moved_rows;"
        STDOUT.write "\r#{n}"
        sleep(1) if n % 50000 == 0
      end
      STDOUT.write "\n"
    end

    # Переносит юзеров с мастера на шард
    def move_from_root
      min = Session.connection.select_value('SELECT min(id) FROM ONLY sessions').to_i
      max = Session.connection.select_value('SELECT max(id) FROM ONLY sessions').to_i
      step = 1000
      (((min / step).to_i * step)..max).step(step) do |n|
        ActiveRecord::Base.connection.execute "with moved_rows AS ( delete FROM ONLY sessions where id < #{(n + step)} AND id >= #{n} returning * ) insert into sessions select * from moved_rows;"
        STDOUT.write "\r#{n}"
        sleep(2) if n % 10000000 == 0 && n <= 200000000 || n % 5000000 == 0 && n > 200000000
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

    # Удаляет пустые сессии без истории и профилей
    def clean_empty(level = 1)
      ActiveRecord::Base.logger.level = level

      count = 0
      batch = 1000
      Session.from('sessions_master as sessions').where('sessions.updated_at IS NULL AND sessions.id >= 230364000')
                       .joins('LEFT JOIN users ON users.id = sessions.user_id')
                       .joins('LEFT JOIN orders ON orders.user_id = sessions.user_id')
                       .where(users: {gender: nil, fashion_sizes: nil, children: nil, allergy: nil, cosmetic_hair: nil, compatibility: nil, vds: nil, pets: nil, jewelry: nil})
                       .where(orders: {id: nil})
                       .select('sessions.id, sessions.user_id')
                       .find_in_batches(batch_size: batch).with_index do |group, n|
        users = group.map(&:user_id)
        if users.count == 0
          STDOUT.write "\r#{n}, count: #{count}"
          next
        end

        # Удаляем все связи
        clients = Client.where(user_id: users).pluck(:id)
        TriggerMail.where(client_id: clients).delete_all
        DigestMail.where(client_id: clients).delete_all
        WebPushTriggerMessage.where(client_id: clients).delete_all
        WebPushDigestMessage.where(client_id: clients).delete_all
        WebPushToken.where(client_id: clients).delete_all
        Client.where(id: clients).delete_all
        Visit.where(user_id: users).delete_all
        SearchQuery.where(user_id: users).delete_all
        UserTaxonomy.where(user_id: users).delete_all
        ProfileEvent.where(user_id: users).delete_all
        SubscribeForCategory.where(user_id: users).delete_all
        SubscribeForProductPrice.where(user_id: users).delete_all
        SubscribeForProductAvailable.where(user_id: users).delete_all
        ClientCart.where(user_id: users).delete_all
        User.where(id: users).delete_all
        Session.where(user_id: users).delete_all
        count += users.count

        STDOUT.write "\r#{n}, count: #{count}"
        sleep(1) if n % 50000 == 0
        return if level == 0
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
      "sessions_#{i % partitions_size}"
    end

  end

end
