class DataManager

  attr_accessor :tables, :size

  def initialize(size = 5)
    @tables = ActiveRecord::Base.connection.tables - ['schema_migrations']
    @size = size
  end

  def fix_ids(shop_id = nil)
    ActiveRecord::Base.logger.level = 1

    tables.each do |table|
      STDOUT.write "#{table}\n\r"

      # Получаем класс модели
      begin
        cls = table.classify.constantize
      rescue
        cls = table.titleize.gsub(/\s/, '').constantize
      end

      # Получаем список зависимостей
      associations = cls.reflect_on_all_associations(:has_many)

      # Выбираем все записи, которые меньше max integer
      rows = cls.where('id < 2147483647')
      rows = rows.where(shop_id: shop_id) if shop_id.present?

      # Проходим по строкам, достаем по 1000
      i = 0
      rows.find_in_batches do |groups|

        # Разбиваем массив по группам
        groups.each_slice(size) do |group|
          threads = []
          group.each do |row|
            i += 1
            if ActiveRecord::Base.logger.level > 0
              STDOUT.write "\r".rjust(i.to_s.length + size)
              STDOUT.write "\r#{i} "
            end

            # Создаем тред
            threads << Thread.new(row) do |row|

              # Получаем функцию nextval
              nextval = ActiveRecord::Base.connection.select_value("SELECT column_default FROM information_schema.columns WHERE (table_schema, table_name) = ('public', '#{table}') AND column_name = 'id'")

              # Получаем следующий id из сиквенса
              id = ActiveRecord::Base.connection.select_value("SELECT #{nextval}")
              row.transaction do

                # Обновляем все связи
                associations.each do |association|
                  Rails.logger.debug association.name

                  # Получаем связанные данные
                  children = row.try(association.name)
                  next if children.nil?

                  # Выполняем все в транзакции
                  children.update_all(association.foreign_key => id)
                end

                # Обновляем саму строку
                row.update_attribute(:id, id)
              end
              STDOUT.write '*' if ActiveRecord::Base.logger.level > 0
            end

          end

          # Запускаем выполнение тасков
          threads.each &:join
        end

      end
      STDOUT.write " done\n\r" if i > 0
    end
    nil
  end

end
