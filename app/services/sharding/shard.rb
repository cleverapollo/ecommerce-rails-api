module Sharding
  class Shard

    class << self

      # Генерирует таблицу соответствия магазинов шардам.
      # По файлу на магазин.
      def generate_nginx_mapping
        CustomLogger.logger.info("START: Sharding::Shard.generate_nginx_mapping")
        Dir.mkdir(File.expand_path('nginx_mapping')) unless Dir.exists?(File.expand_path('nginx_mapping'))
        Shop.unscoped.active.select(:id, :uniqid, :shard).each do |project|
          File.open(File.expand_path(project.uniqid, 'nginx_mapping'), 'w') { |file| file.write(project.shard) }
        end
        directory = Dir.new(File.expand_path('nginx_mapping'))

        # Удаляем неактивные магазины
        active_shop_codes = Shop.unscoped.active.pluck(:uniqid)
        while file = directory.read
          if file.match(/^[a-f0-9]+$/)
            unless active_shop_codes.include? file
              File.unlink( File.expand_path(file, 'nginx_mapping') )
            end
          end
        end
        CustomLogger.logger.info("END: Sharding::Shard.generate_nginx_mapping")
      end

    end

  end
end
