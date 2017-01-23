module DigestMailings
  class Mytoys

    class << self

      def sync
        # MyToys
        shop = Shop.find 828
        recommendations_count = 9
        digest_path = 'tmp/mytoys_digests.csv'

        # Создаем новый файл или обнуляем старый
        file_source = File.open(File.join(Rails.root, digest_path), 'w+')

        clients = shop.clients.with_email.suitable_for_digest_mailings.includes(:user)
        DigestMailingRecommendationsCalculator.open(shop, recommendations_count) do |calculator|
          clients.each do |client|
            if IncomingDataTranslator.email_valid?(client.email)
              recommendations = calculator.recommendations_for(client.user).map { |r| r.uniqid }
              file_source.puts "#{client.email};#{recommendations.join(',')}"
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
            session = Net::SSH.start('ftpapi.broadmail.de', 'r_mytoysru_partner')
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