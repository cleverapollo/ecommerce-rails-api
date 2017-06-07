module DigestMailings
  class Mytoys

    class << self

      # @param [Integer] size Количество запускаемых потоков
      def sync(size = 5)
        begin
          # MyToys
          shop = Shop.find 828
        rescue ActiveRecord::RecordNotFound
          return false
        end
        recommendations_count = 9
        digest_path = 'tmp/optivo_mytoys/digests.csv'
        path = File.join(Rails.root, digest_path)

        # Создаем каталог, если он отсутствует
        unless Dir.exists?('tmp/optivo_mytoys')
          Dir.mkdir('tmp/optivo_mytoys', 0700)
        end

        # Можно работать?
        if sending_available?
          # Ставим блокировку
          start_sending!

          begin
            # Удаляем файл, если существует
            File.delete(path) if File.exist?(path)

            DigestMailingRecommendationsCalculator.open(shop, recommendations_count) do |calculator|

              clients = shop.clients.suitable_for_digest_mailings.includes(:user)

              # Для юзера без истории и профиля здесь будем хранить дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
              empty_user_recommendations = nil

              i = 0
              clients.find_in_batches do |groups|

                # Разбиваем массив по группам
                groups.each_slice(size) do |group|
                  threads = []
                  group.each do |client|
                    i += 1
                    if ActiveRecord::Base.logger.level > 0
                      STDOUT.write "\r".rjust(i.to_s.length + size)
                      STDOUT.write "\r#{i} "
                    end

                    # Проверяем валидность email
                    if IncomingDataTranslator.email_valid?(client.email)

                      # Создаем тред
                      threads << Thread.new(client) do |client|

                        # Для юзера без истории и профиля здесь будем использовать дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
                        if !client.user.orders.where(shop_id: 828).exists? && (client.user.children.nil? || (client.user.children.is_a?(Array) && client.user.children.empty?))
                          if empty_user_recommendations.nil?
                            empty_user_recommendations = calculator.recommendations_for(client.user).map { |r| r.uniqid }
                          end
                          recommendations = empty_user_recommendations
                        else
                          recommendations = calculator.recommendations_for(client.user).map { |r| r.uniqid }
                        end

                        # Добавляем строку в файл
                        File.open(path, 'a') do |file_source|
                          file_source.flock(File::LOCK_EX)
                          file_source.puts "#{client.email};#{recommendations.join(',')}"
                          file_source.flock(File::LOCK_UN)
                        end

                        STDOUT.write '*' if ActiveRecord::Base.logger.level > 0
                      end
                    end

                  end

                  # Запускаем выполнение тасков
                  threads.each &:join
                end

              end
            end

            file_source.close

            # Отправляем на sFTP (только в production mode и только для 828 магазина)
            if Rails.env.production?
              require 'net/ssh'
              require 'net/ftp'
              require 'net/sftp'

              begin
                session = Net::SSH.start('ftpapi.broadmail.de', 'r_mytoysru_partner', timeout: 5)
                sftp = Net::SFTP::Session.new(session).connect!
                sftp.upload!(digest_path, 'digests.csv') if File.exists? digest_path
                sftp.close_channel
                Rollbar.info('MyToys digest upload success')
              rescue Exception => e
                Rollbar.error(e)
              end
            end

            true
          ensure
            # Отменяем блокировку по завершению процесса
            stop_sending!
          end
        else
          Rails.logger.error 'Already running'
          Rollbar.warn 'Digest MyToys already running'
        end
      end

      private

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

      def path_file
        "#{Rails.root}/tmp/pids/digest_mytoys.pid"
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

    end

  end
end
