module TriggerMailings
  class TriggerMailingTimeLock

    # @return [Shop]
    attr_accessor :shop

    # @param [Shop] shop
    def initialize(shop)
      @shop = shop
    end

    def sending_available?
      # проверка pid файла
      if File.exists?(path_file)
        data = File.read(path_file)
        # проверка pid процесса
        begin
          Process.getpgid( data.to_i )
          false
        rescue Errno::ESRCH
          true
        end
      else
        true
      end
    end

    def start_sending!
      # создание pid файла
      File.open(path_file, 'w+') do |f|
        f.write(Process.pid.to_s)
      end
    end

    def stop_sending!
      # удаление pid файла
      File.delete(path_file)
    end

    private

    def path_file
      "#{Rails.root}/tmp/pids/trigger_sending_#{shop.id}.pid"
    end
  end
end
