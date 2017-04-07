class DataManager

  attr_accessor :tables

  def initialize
    @tables = ActiveRecord::Base.connection.tables - ['schema_migrations']
  end

  def fix_ids
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
      next if rows.length == 0
      STDOUT.write "found: #{rows.length}\n\r"

      # Проходим по строкам
      rows.find_each.with_index do |row, index|
        STDOUT.write "\r#{(index.to_f / rows.length * 100).round(1)}%" if ActiveRecord::Base.logger.level > 0

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
      end
      STDOUT.write "\r"
    end
    nil
  end

end
