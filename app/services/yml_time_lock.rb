class YmlTimeLock
  def process_available?
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

  def start_processing!
    # создание pid файла
    File.open(path_file, "w+") do |f|
      f.write(Process.pid.to_s)
    end
  end

  def stop_processing!
    # удаление pid файла
    File.delete(path_file)
  end

  private

  def path_file
    "#{Rails.root}/tmp/yml_processing.pid"
  end
end
