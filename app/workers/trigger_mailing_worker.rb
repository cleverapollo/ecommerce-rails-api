class TriggerMailingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'trigger'

  # @param [Integer] shop_id
  def perform(shop_id)

    # @type shop [Shop]
    shop = Shop.find(shop_id)

    # @type lock [TriggerMailings::TriggerMailingTimeLock] Инициализируем блокировку
    lock = TriggerMailings::TriggerMailingTimeLock.new(shop)

    # Можно работать?
    if lock.sending_available?
      # Ставим блокировку
      lock.start_sending!

      begin
        # Изменяем временную зону в зону владельца магазина
        Time.use_zone(shop.customer.time_zone) do

          TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|
            get_response_client = nil

            # Настройки рассылки для тех, кто использует внешний транспорт
            if shop.mailings_settings.external_getresponse?
              begin
                get_response_client = Mailings::GetResponseClient.new(shop).prepare
              rescue StandardError => e
                # todo уведомлять клиента по почте
                Rollbar.warning(e)
                next
              end
            end

            triggers_to_send = {} if shop.mailings_settings.external_mailchimp?

            # Сначала перебираем вторые брошенные корзины
            if trigger_detector.triggers_classes.include?(TriggerMailings::Triggers::SecondAbandonedCart)

              # Читаем данные со slave сервера
              Slavery.on_slave do

                # Проходим по списку клиентов магазина
                shop.clients.ready_for_second_abandoned_cart(shop).find_each do |client|
                  Slavery.on_master do
                    begin
                      # @type [TriggerMailings::Triggers::Base] trigger
                      trigger = trigger_detector.detect(client)
                      if trigger.present?
                        trigger.letter(client, get_response_client)

                        # Для mailchimp немного другая логика
                        if shop.mailings_settings.external_mailchimp?
                          trigger_type = trigger.type
                          triggers_to_send[trigger_type].present? ? triggers_to_send[trigger_type] << trigger : triggers_to_send[trigger_type] = [trigger]
                        end
                      end


                      # # todo перенести, возможно в
                      # trigger = trigger_detector.detect(client)
                      # if trigger.present?
                      #   if shop.mailings_settings.external_getresponse?
                      #     TriggerMailings::GetResponseLetter.new(client, trigger, get_response_client).send
                      #   elsif shop.mailings_settings.external_ofsys?
                      #     result = TriggerMailings::OfsysLetter.new(client, trigger).send
                      #     next unless result
                      #   elsif shop.mailings_settings.is_optivo_for_mytoys?
                      #     TriggerMailings::OptivoMytoysLetter.new(client, trigger).send
                      #   elsif shop.mailings_settings.external_mailganer?
                      #     TriggerMailings::MailganerLetter.new(client, trigger).send
                      #   elsif shop.mailings_settings.external_mailchimp?
                      #     triggers_to_send[:second_abandoned_cart].present? ? triggers_to_send[:second_abandoned_cart] << trigger :  triggers_to_send[:second_abandoned_cart] = [trigger]
                      #   else
                      #     begin
                      #       TriggerMailings::Letter.new(client, trigger).send
                      #     rescue TriggerMailings::Letter::EmptyProductsCollectionError => e
                      #       # Если вдруг не было товаров к рассылке, то просто ничего не делаем. Письмо в базе остается как будто отправленное.
                      #       # Костыль, конечно, но пока так.
                      #     end
                      #   end
                      #   unless shop.mailings_settings.external_mailchimp?
                      #     client.update_columns(last_trigger_mail_sent_at: Time.now)
                      #     client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
                      #   end
                      # end
                    rescue StandardError => e
                      Rails.logger.error e
                      Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                    end
                  end

                end

              end

            end

            # Читаем данные со slave сервера
            Slavery.on_slave do
              # Затем перебираем обычные триггеры
              shop.clients.ready_for_trigger_mailings(shop).find_each do |client|
                Slavery.on_master do
                  begin
                    # @type [TriggerMailings::Triggers::Base] trigger
                    trigger = trigger_detector.detect(client)
                    if trigger.present?
                      trigger.letter(client, get_response_client)

                      # Для mailchimp немного другая логика
                      if shop.mailings_settings.external_mailchimp?
                        trigger_type = trigger.type
                        triggers_to_send[trigger_type].present? ? triggers_to_send[trigger_type] << trigger : triggers_to_send[trigger_type] = [trigger]
                      end

                      # if shop.mailings_settings.external_getresponse?
                      #   TriggerMailings::GetResponseLetter.new(client, trigger, get_response_client).send
                      # elsif shop.mailings_settings.external_ofsys?
                      #   result = TriggerMailings::OfsysLetter.new(client, trigger).send
                      #   next unless result
                      # elsif shop.mailings_settings.is_optivo_for_mytoys?
                      #   TriggerMailings::OptivoMytoysLetter.new(client, trigger).send
                      # elsif shop.mailings_settings.external_mailganer?
                      #   TriggerMailings::MailganerLetter.new(client, trigger).send
                      # elsif shop.mailings_settings.external_mailchimp?
                      #   trigger_type = trigger.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore.to_sym
                      #   triggers_to_send[trigger_type].present? ? triggers_to_send[trigger_type] << trigger :  triggers_to_send[trigger_type] = [trigger]
                      # else
                      #   begin
                      #     TriggerMailings::Letter.new(client, trigger).send
                      #   rescue TriggerMailings::Letter::EmptyProductsCollectionError => e
                      #     # Если вдруг не было товаров к рассылке, то просто ничего не делаем. Письмо в базе остается как будто отправленное.
                      #     # Костыль, конечно, но пока так.
                      #   end
                      # end
                      # unless shop.mailings_settings.external_mailchimp?
                      #   client.update_columns(last_trigger_mail_sent_at: Time.now)
                      #   client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
                      # end
                    end
                  rescue StandardError => e
                    Rails.logger.error e
                    Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                  end
                end
              end
            end

            begin
              Mailings::Mailchimp::TriggersSender.new(triggers_to_send, shop.mailings_settings.mailchimp_api_key, shop.id).send_all if shop.mailings_settings.external_mailchimp? && triggers_to_send.present?
            rescue StandardError => e
              Rollbar.error(e, mailchimp_trigger: shop.id)
            end
          end

        end

      ensure
        # Отменяем блокировку по завершению процесса
        lock.stop_sending!
      end
    else
      Rollbar.warn('Trigger process too long', shop_id: shop_id)
    end
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end