module TriggerMailings
  class OptivoMytoysLetter < TriggerMailings::Letter

    attr_accessor :api

    class << self

      # Выгружает триггеры в Optivo и удаляет устаревшие данные
      # Note: если автотест не проходит
      # http://y.mkechinov.ru/issue/REES-2447
      def sync

        # Создаем каталог, если он отсутствует
        if !Dir.exists?("tmp/optivo_mytoys")
          Dir.mkdir("tmp/optivo_mytoys", 0700)
        end

        mails = TriggerMailingQueue.where('triggered_at <= ?', Time.current)
        trigger_types = mails.pluck(:trigger_type).uniq
        emails = mails.pluck(:email).uniq.compact

        # Формируем файлы для отправки

        trigger_types_matching = {
            abandoned_cart:           { code: 'Abadonded_busket',           file_source: 'rees46_abbusket.csv',         file_recommendations_1: 'rees46_abbusket_reco.csv',       file_recommendations_2: 'rees46_abbusket_reco_2.csv' },
            second_abandoned_cart:    { code: 'Abadonded_busket_second',    file_source: 'rees46_secabbusket.csv',      file_recommendations_1: 'rees46_secabbusket_reco.csv',    file_recommendations_2: 'rees46_secabbusket_reco_2.csv' },
            viewed_but_not_bought:    { code: 'Article_view',               file_source: 'rees46_articleview.csv',      file_recommendations_1: 'rees46_articleview_reco.csv',    file_recommendations_2: 'rees46_articleview_reco_2.csv' },
            recently_purchased:       { code: 'Recently_purchase',          file_source: 'rees46_recpurchase.csv',      file_recommendations_1: 'rees46_recpurchase_reco.csv',    file_recommendations_2: 'rees46_recpurchase_reco_2.csv' },
            low_on_supply:            { code: 'Will_end',                   file_source: 'rees46_wiilend.csv',          file_recommendations_1: 'rees46_wiilend_reco.csv',        file_recommendations_2: 'rees46_wiilend_reco_2.csv' },
            product_available:        { code: 'In_stock',                   file_source: 'rees46_instock.csv',          file_recommendations_1: 'rees46_instock_reco.csv',        file_recommendations_2: 'rees46_instock_reco_2.csv' },
            abandoned_search:         { code: 'Abadonded_search',           file_source: 'rees46_absearch.csv',         file_recommendations_1: 'rees46_absearch_reco.csv',       file_recommendations_2: 'rees46_absearch_reco_2.csv' },
            abandoned_category:       { code: 'Abadonded_cat',              file_source: 'rees46_catview.csv',          file_recommendations_1: 'rees46_catview_reco.csv',        file_recommendations_2: 'rees46_catview_reco_2.csv' },
            retention:                { code: 'Monthly_mail',               file_source: 'rees46_monthly.csv',          file_recommendations_1: 'rees46_monthly_reco.csv',        file_recommendations_2: 'rees46_monthly_reco_2.csv' },
            product_price_decrease:   { code: 'PriceDropped',               file_source: 'rees_pricedroped.csv',        file_recommendations_1: 'rees46_pricedroped_reco.csv',    file_recommendations_2: 'rees46_pricedroped_reco_2.csv' },
        }

        if emails.any?

          # Перебираем все типы триггеров и формируем файлы для рекоменадций, удаляя файлы с предыдущего экспорта
          trigger_types_matching.each do |trigger_type, trigger_config|

            # Удаляем старые файлы, если были
            File.delete("tmp/optivo_mytoys/#{trigger_config[:file_source]}") if File.exists?("tmp/optivo_mytoys/#{trigger_config[:file_source]}")
            File.delete("tmp/optivo_mytoys/#{trigger_config[:file_recommendations_1]}") if File.exists?("tmp/optivo_mytoys/#{trigger_config[:file_recommendations_1]}")
            File.delete("tmp/optivo_mytoys/#{trigger_config[:file_recommendations_2]}") if File.exists?("tmp/optivo_mytoys/#{trigger_config[:file_recommendations_2]}")

            # Создаем новые файлы для текущего триггера
            file_source = File.open(File.join(Rails.root, "tmp/optivo_mytoys/#{trigger_config[:file_source]}"), 'w+')
            file_recommendations_1 = File.open(File.join(Rails.root, "tmp/optivo_mytoys/#{trigger_config[:file_recommendations_1]}"), 'w+')
            file_recommendations_2 = File.open(File.join(Rails.root, "tmp/optivo_mytoys/#{trigger_config[:file_recommendations_2]}"), 'w+')

            # Перебираем все письма для этого триггера
            mails.where(trigger_type: trigger_type.to_s).each do |trigger_data|

              # Сохраняем файл с исходными товарами триггера
              if trigger_data.source_items && trigger_data.source_items.is_a?(Array) && trigger_data.source_items.any?
                # file_source.puts "#{trigger_data.email};#{trigger_data.source_items[0..3].join(',')};recommended_by=trigger_mail&rees46_trigger_mail_code=#{trigger_data.trigger_mail_code}"
                file_source.puts "#{trigger_data.email};#{trigger_data.source_items[0..3].join(',')}"
              end

              # Сохраняем файлы с рекомендованными товарами триггера
              if trigger_data.recommended_items && trigger_data.recommended_items.is_a?(Array) && trigger_data.recommended_items.any?
                # file_recommendations_1.puts "#{trigger_data.email};#{trigger_data.recommended_items[0..3].join(',')};recommended_by=trigger_mail&rees46_trigger_mail_code=#{trigger_data.trigger_mail_code}" if trigger_data.recommended_items[0..3]
                # file_recommendations_2.puts "#{trigger_data.email};#{trigger_data.recommended_items[4..7].join(',')};recommended_by=trigger_mail&rees46_trigger_mail_code=#{trigger_data.trigger_mail_code}" if trigger_data.recommended_items[4..7]
                file_recommendations_1.puts "#{trigger_data.email};#{trigger_data.recommended_items[0..3].join(',')}" if trigger_data.recommended_items[0..3]
                file_recommendations_2.puts "#{trigger_data.email};#{trigger_data.recommended_items[4..7].join(',')}" if trigger_data.recommended_items[4..7]
              end
            end

            file_source.close
            file_recommendations_1.close
            file_recommendations_2.close

          end

          # Формируем файлы оглавления rees46triggeremails.csv
          File.delete("tmp/optivo_mytoys/rees46triggeremails.csv") if File.exists?("tmp/optivo_mytoys/rees46triggeremails.csv")
          rees46triggeremails_csv = File.open(File.join(Rails.root, "tmp/optivo_mytoys/rees46triggeremails.csv"), 'w+')
          rees46triggeremails_csv.puts "Email;#{trigger_types_matching.map{|k,v| v[:code]}.join(';')};Reco_Mapping_List\n"
          emails.each do |email|
            row = "#{email};"
            trigger_types_matching.each do |trigger_type, trigger_name|
              row += (mails.where(email: email, trigger_type: trigger_type.to_s).exists? ? 'Y' : 'N' ) + ";"
            end
            rees46triggeremails_csv.puts row
          end
          rees46triggeremails_csv.close

          # Отправляем на sFTP (только в production mode)

          if Rails.env.production?

            require 'net/ssh'
            require 'net/ftp'
            require 'net/sftp'

            begin
              session = Net::SSH.start('ftpapi.broadmail.de', 'r_mytoysru_partner')
              sftp = Net::SFTP::Session.new(session).connect!
              trigger_types_matching.each do |key, trigger|
                sftp.upload!("tmp/optivo_mytoys/#{trigger[:file_source]}", trigger[:file_source])                         if File.exists? "tmp/optivo_mytoys/#{trigger[:file_source]}"
                sftp.upload!("tmp/optivo_mytoys/#{trigger[:file_recommendations_1]}", trigger[:file_recommendations_1])   if File.exists? "tmp/optivo_mytoys/#{trigger[:file_recommendations_1]}"
                sftp.upload!("tmp/optivo_mytoys/#{trigger[:file_recommendations_2]}", trigger[:file_recommendations_2])   if File.exists? "tmp/optivo_mytoys/#{trigger[:file_recommendations_2]}"
              end
              sftp.upload!("tmp/optivo_mytoys/rees46triggeremails.csv", "rees46triggeremails.csv")
            rescue Exception => e
              Rollbar.error(e)
            end

          end

          # Удаляем ненужные файлы
          trigger_types_matching.each do |key, trigger|
            File.delete "tmp/optivo_mytoys/#{trigger[:file_source]}" if File.exists? "tmp/optivo_mytoys/#{trigger[:file_source]}"
            File.delete "tmp/optivo_mytoys/#{trigger[:file_recommendations_1]}" if File.exists? "tmp/optivo_mytoys/#{trigger[:file_recommendations_1]}"
            File.delete "tmp/optivo_mytoys/#{trigger[:file_recommendations_2]}" if File.exists? "tmp/optivo_mytoys/#{trigger[:file_recommendations_2]}"
          end
          File.delete "tmp/optivo_mytoys/rees46triggeremails.csv" if File.exists? "tmp/optivo_mytoys/rees46triggeremails.csv"

        end

        mails.delete_all
        true
      end

    end


    def initialize(client, trigger)
      @client = client
      @shop = @client.shop
      @trigger = trigger
      @trigger_mail = client.trigger_mails.create!(
          mailing: trigger.mailing,
          shop: client.shop,
          trigger_data: {
              trigger: trigger.to_json
          }
      ).reload
    end

    # Сохраняем в базу триггер
    def send
      data = {
        triggered_at: Time.now,
        user_id: @client.user_id,
        shop_id: @shop.id,
        trigger_type: @trigger.code.underscore,
        recommended_items: @trigger.recommended_ids(8),
        source_items: [],
        email: client.email,
        trigger_mail_code: @trigger_mail.code
      }

      if @trigger.source_items.present? && @trigger.source_items.is_a?(Array)
        data[:source_items] = @trigger.source_items.map(&:uniqid)
      end

      TriggerMailingQueue.create! data
    end


  end
end
