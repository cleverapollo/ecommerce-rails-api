module DigestMailings
  class Mytoys

    class << self

      def sync
        begin
          # MyToys
          shop = Shop.find 828
        rescue ActiveRecord::RecordNotFound
          return false
        end
        recommendations_count = 9
        digest_path = 'tmp/optivo_mytoys/digests.csv'

        # Создаем каталог, если он отсутствует
        unless Dir.exists?('tmp/optivo_mytoys')
          Dir.mkdir('tmp/optivo_mytoys', 0700)
        end

        # Создаем новый файл или обнуляем старый
        file_source = File.open(File.join(Rails.root, digest_path), 'w+')

        DigestMailingRecommendationsCalculator.open(shop, recommendations_count) do |calculator|

          Slavery.on_slave do
            clients = shop.clients.suitable_for_digest_mailings.includes(:user)

            # Для юзера без истории и профиля здесь будем хранить дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
            empty_user_recommendations = nil

            clients.find_each do |client|
              Slavery.on_master do
                if IncomingDataTranslator.email_valid?(client.email)

                  # Для юзера без истории и профиля здесь будем использовать дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
                  if !client.user.orders.where(shop_id: 828).exists? && (client.user.children.nil? || (client.user.children.is_a?(Array) && client.user.children.empty?))
                    if empty_user_recommendations.nil?
                      empty_user_recommendations = calculator.recommendations_for(client.user).map { |r| r.uniqid }
                    end
                    recommendations = empty_user_recommendations
                  else
                    recommendations = calculator.recommendations_for(client.user).map { |r| r.uniqid }
                  end

                  file_source.puts "#{client.email};#{recommendations.join(',')}"
                end
              end
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
          rescue Exception => e
            Rollbar.error(e)
          end
        end

        true
      end

    end

  end
end